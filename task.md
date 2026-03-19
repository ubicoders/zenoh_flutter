

1. it has android zenoh.so in /android/app/src/main/jniLibs. the app (main.dart) should really use the zenoh tcp or udp or ws. instead of just ws. but currently it is not.


2. the router is running here

version: '3.8'

services:
  zenoh-router:
    image: eclipse/zenoh:latest
    network_mode: "host"
    # ports:
    #   - "7447:7447/tcp"
    #   - "7447:7447/udp"
    #   - "8000:8000/tcp"
    healthcheck:
      test: [ "CMD", "nc", "-z", "localhost", "7447" ]
      interval: 2s
      timeout: 2s
      retries: 5
    command: [ "--listen", "tcp/[::]:7447", "--listen", "udp/[::]:7447", "--listen", "ws/[::]:8000" ]



3. and the pusliserh

services:
  publisher:
    build: ./publisher
    network_mode: "host"
    environment:
      - PYTHONUNBUFFERED=1

with the python script
```
import zenoh
import time

def main():
    # The "node" name isn't formally defined like in ROS, but we can think of
    # this script as the "Publisher Node". It connects to the router as a client.
    print("Starting publisher...", flush=True)
    conf = zenoh.Config()
    conf.insert_json5("connect/endpoints", '["tcp/localhost:7447"]')
    conf.insert_json5("mode", '"client"')
    # Add retry to connection configuration
    import json
    conf.insert_json5("connect/retry", '{"max_delay_ms": 1000}')
    
    print("Connecting to Zenoh Router at tcp/localhost:7447...", flush=True)
    session = zenoh.open(conf)
    print("Successfully connected!", flush=True)
    
    # Declare a publisher on a specific topic (key expression in Zenoh)
    # The topic here is "test/topic". Any subscriber listening to "test/topic" 
    # (or a wildcard like "test/**") will receive these messages.
    pub = session.declare_publisher("test/topic")
    
    count = 0
    try:
        while True:
            msg = f"Message {count} from publisher 1"
            print(f"Publishing: {msg}", flush=True)
            pub.put(msg)
            count += 1
            time.sleep(2)
    except KeyboardInterrupt:
        pass
    finally:
        session.close()

if __name__ == "__main__":
    main()

```


4. then the susbcriber is actually working with
services:
  subscriber:
    build: ./subscriber
    network_mode: "host"
    environment:
      - PYTHONUNBUFFERED=1


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

    print("Connecting to Zenoh Router at tcp/localhost:7447...", flush=True)
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


5. this is all in this computer
6. the android emulator is runnign in this ubuntu 24 machine. Android Emulator - Medium-Phone_api_36.1:5554
7. can you make zenoh dart work on this example with the android emulator?
