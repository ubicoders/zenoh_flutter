import zenoh
import time

def listener(sample):
    # Depending on zenoh version, payload is either bytes directly or has to_string/to_bytes
    try:
        msg = sample.payload.to_string()
    except AttributeError:
        # Fallback for older/newer variations if any
        msg = str(sample.payload)
        
    print(f"Received: {sample.kind} on {sample.key_expr} with payload: {msg}", flush=True)

def main():
    # The "node" name isn't formally defined like in ROS, but we can think of
    # this script as the "Subscriber Node". It connects to the router as a client.
    print("Starting subscriber...", flush=True)
    conf = zenoh.Config()
    # conf.insert_json5("connect/endpoints", '["tcp/192.168.0.101:7447"]')
    conf.insert_json5("connect/endpoints", '["tcp/localhost:7447"]')
    conf.insert_json5("mode", '"client"')
    # Add retry to connection configuration
    conf.insert_json5("connect/retry", '{"max_delay_ms": 1000}')

    print("Connecting to Zenoh Router at tcp/127.0.0.1:7447...", flush=True)
    session = zenoh.open(conf)
    print("Successfully connected!", flush=True)
    
    # Declare a subscriber on a wildcard topic (key expression in Zenoh)
    # The topic here is "test/**". This subscriber will receive messages
    # from any publisher that publishes to "test/topic" or "test/topic2" etc.
    sub = session.declare_subscriber("test/**", listener)
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        sub.undeclare()
        session.close()

if __name__ == "__main__":
    main()
