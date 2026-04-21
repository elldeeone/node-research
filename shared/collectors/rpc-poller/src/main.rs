use chrono::{SecondsFormat, Utc};
use kaspa_grpc_client::GrpcClient;
use kaspa_rpc_core::{api::rpc::RpcApi, notify::mode::NotificationMode};
use std::{
    env,
    fs::{self, File},
    io::{BufWriter, Write},
    path::PathBuf,
    time::{Duration, Instant},
};

struct Config {
    url: String,
    out: PathBuf,
    interval_sec: u64,
    duration_sec: u64,
}

fn usage() -> &'static str {
    "Usage:\n  cargo run --manifest-path shared/collectors/rpc-poller/Cargo.toml -- \\\n    --url grpc://127.0.0.1:16110 \\\n    --out shared/collectors/runs/<run-id>/rpc-metrics.csv \\\n    [--interval-sec 1] [--duration-sec 0]\n\nNotes:\n  - duration 0 means run until Ctrl-C\n  - output is raw CSV for later summarization\n"
}

fn parse_args() -> Result<Config, String> {
    let mut url = String::from("grpc://127.0.0.1:16110");
    let mut out: Option<PathBuf> = None;
    let mut interval_sec = 1_u64;
    let mut duration_sec = 0_u64;

    let mut args = env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--url" => {
                url = args.next().ok_or_else(|| String::from("missing value for --url"))?;
            }
            "--out" => {
                out = Some(PathBuf::from(args.next().ok_or_else(|| String::from("missing value for --out"))?));
            }
            "--interval-sec" => {
                interval_sec = args
                    .next()
                    .ok_or_else(|| String::from("missing value for --interval-sec"))?
                    .parse()
                    .map_err(|_| String::from("invalid integer for --interval-sec"))?;
            }
            "--duration-sec" => {
                duration_sec = args
                    .next()
                    .ok_or_else(|| String::from("missing value for --duration-sec"))?
                    .parse()
                    .map_err(|_| String::from("invalid integer for --duration-sec"))?;
            }
            "-h" | "--help" => {
                return Err(String::new());
            }
            _ => return Err(format!("unknown arg: {arg}")),
        }
    }

    let out = out.ok_or_else(|| String::from("missing required --out"))?;
    Ok(Config { url, out, interval_sec, duration_sec })
}

fn csv_cell(value: &str) -> String {
    if value.contains(',') || value.contains('"') || value.contains('\n') {
        format!("\"{}\"", value.replace('"', "\"\""))
    } else {
        value.to_string()
    }
}

fn bool_str(value: bool) -> &'static str {
    if value { "1" } else { "0" }
}

fn write_header(writer: &mut BufWriter<File>) -> std::io::Result<()> {
    writeln!(
        writer,
        "timestamp_utc,elapsed_sec,rpc_ok,server_time,p2p_id,server_version,is_utxo_indexed,is_synced,info_mempool_size,\
borsh_live_connections,borsh_connection_attempts,borsh_handshake_failures,json_live_connections,json_connection_attempts,\
json_handshake_failures,active_peers,borsh_bytes_tx,borsh_bytes_rx,json_bytes_tx,json_bytes_rx,p2p_bytes_tx,p2p_bytes_rx,\
grpc_bytes_tx,grpc_bytes_rx,node_blocks_submitted_count,node_headers_processed_count,node_dependencies_processed_count,\
node_bodies_processed_count,node_transactions_processed_count,node_chain_blocks_processed_count,node_mass_processed_count,\
node_database_blocks_count,node_database_headers_count,network_mempool_size,network_tip_hashes_count,network_difficulty,\
network_past_median_time,network_virtual_parent_hashes_count,network_virtual_daa_score,error"
    )
}

async fn connect(url: &str) -> Result<GrpcClient, String> {
    GrpcClient::connect_with_args(NotificationMode::Direct, url.to_string(), None, false, None, false, Some(5_000), Default::default())
        .await
        .map_err(|err| err.to_string())
}

async fn write_success_row(writer: &mut BufWriter<File>, elapsed_sec: f64, client: &GrpcClient) -> Result<(), String> {
    let info = client.get_info().await.map_err(|err| err.to_string())?;
    let metrics = client.get_metrics(true, true, true, true, false, false).await.map_err(|err| err.to_string())?;

    let connection = metrics.connection_metrics.unwrap_or_default();
    let bandwidth = metrics.bandwidth_metrics.unwrap_or_default();
    let consensus = metrics.consensus_metrics.unwrap_or_default();

    let cells = [
        Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true),
        format!("{elapsed_sec:.3}"),
        String::from("1"),
        metrics.server_time.to_string(),
        info.p2p_id,
        info.server_version,
        bool_str(info.is_utxo_indexed).to_string(),
        bool_str(info.is_synced).to_string(),
        info.mempool_size.to_string(),
        connection.borsh_live_connections.to_string(),
        connection.borsh_connection_attempts.to_string(),
        connection.borsh_handshake_failures.to_string(),
        connection.json_live_connections.to_string(),
        connection.json_connection_attempts.to_string(),
        connection.json_handshake_failures.to_string(),
        connection.active_peers.to_string(),
        bandwidth.borsh_bytes_tx.to_string(),
        bandwidth.borsh_bytes_rx.to_string(),
        bandwidth.json_bytes_tx.to_string(),
        bandwidth.json_bytes_rx.to_string(),
        bandwidth.p2p_bytes_tx.to_string(),
        bandwidth.p2p_bytes_rx.to_string(),
        bandwidth.grpc_bytes_tx.to_string(),
        bandwidth.grpc_bytes_rx.to_string(),
        consensus.node_blocks_submitted_count.to_string(),
        consensus.node_headers_processed_count.to_string(),
        consensus.node_dependencies_processed_count.to_string(),
        consensus.node_bodies_processed_count.to_string(),
        consensus.node_transactions_processed_count.to_string(),
        consensus.node_chain_blocks_processed_count.to_string(),
        consensus.node_mass_processed_count.to_string(),
        consensus.node_database_blocks_count.to_string(),
        consensus.node_database_headers_count.to_string(),
        consensus.network_mempool_size.to_string(),
        consensus.network_tip_hashes_count.to_string(),
        consensus.network_difficulty.to_string(),
        consensus.network_past_median_time.to_string(),
        consensus.network_virtual_parent_hashes_count.to_string(),
        consensus.network_virtual_daa_score.to_string(),
        String::new(),
    ];

    let row = cells.iter().map(|cell| csv_cell(cell)).collect::<Vec<_>>().join(",");
    writeln!(writer, "{row}").map_err(|err| err.to_string())
}

fn write_error_row(writer: &mut BufWriter<File>, elapsed_sec: f64, error: &str) -> Result<(), String> {
    let mut cells = vec![String::new(); 40];
    cells[0] = Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true);
    cells[1] = format!("{elapsed_sec:.3}");
    cells[2] = String::from("0");
    cells[39] = error.to_string();
    let row = cells.iter().map(|cell| csv_cell(cell)).collect::<Vec<_>>().join(",");
    writeln!(writer, "{row}").map_err(|err| err.to_string())
}

#[tokio::main]
async fn main() -> std::process::ExitCode {
    let config = match parse_args() {
        Ok(config) => config,
        Err(message) if message.is_empty() => {
            print!("{}", usage());
            return std::process::ExitCode::SUCCESS;
        }
        Err(message) => {
            eprintln!("{message}\n\n{}", usage());
            return std::process::ExitCode::FAILURE;
        }
    };

    if let Some(parent) = config.out.parent()
        && let Err(err) = fs::create_dir_all(parent)
    {
        eprintln!("failed to create output dir: {err}");
        return std::process::ExitCode::FAILURE;
    }

    let file = match File::create(&config.out) {
        Ok(file) => file,
        Err(err) => {
            eprintln!("failed to create output file: {err}");
            return std::process::ExitCode::FAILURE;
        }
    };

    let mut writer = BufWriter::new(file);
    if let Err(err) = write_header(&mut writer) {
        eprintln!("failed to write CSV header: {err}");
        return std::process::ExitCode::FAILURE;
    }

    let start = Instant::now();
    let sample_interval = Duration::from_secs(config.interval_sec.max(1));
    let mut client: Option<GrpcClient> = None;

    loop {
        let elapsed_sec = start.elapsed().as_secs_f64();
        if config.duration_sec > 0 && elapsed_sec >= config.duration_sec as f64 {
            break;
        }

        if client.is_none() {
            match connect(&config.url).await {
                Ok(new_client) => client = Some(new_client),
                Err(error) => {
                    if let Err(write_err) = write_error_row(&mut writer, elapsed_sec, &error) {
                        eprintln!("failed to write CSV row: {write_err}");
                        return std::process::ExitCode::FAILURE;
                    }
                    let _ = writer.flush();
                    tokio::select! {
                        _ = tokio::time::sleep(sample_interval) => {}
                        _ = tokio::signal::ctrl_c() => break,
                    }
                    continue;
                }
            }
        }

        let result = if let Some(current_client) = client.as_ref() {
            write_success_row(&mut writer, elapsed_sec, current_client).await
        } else {
            Err(String::from("rpc client missing"))
        };

        if let Err(error) = result {
            let _ = write_error_row(&mut writer, elapsed_sec, &error);
            if let Some(current_client) = client.take() {
                let _ = current_client.disconnect().await;
            }
        }

        if let Err(err) = writer.flush() {
            eprintln!("failed to flush output: {err}");
            return std::process::ExitCode::FAILURE;
        }

        tokio::select! {
            _ = tokio::time::sleep(sample_interval) => {}
            _ = tokio::signal::ctrl_c() => break,
        }
    }

    if let Some(current_client) = client {
        let _ = current_client.disconnect().await;
    }

    std::process::ExitCode::SUCCESS
}
