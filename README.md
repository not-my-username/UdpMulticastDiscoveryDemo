# UdpMulticastDiscoDemo

A simple demonstration of device discovery over UDP multicast in Godot.  
Each running instance periodically broadcasts a small identifier to a multicast group. Other instances listening on the same group will detect and list each other.

## How to Run
1. Download, open, and run the project in the **Godot Editor**.
2. In the UI, choose a **network interface** from the list.
3. Click **Start**.
4. Any other devices (or additional instances of the project on the same LAN) running the demo will appear in the device list at the top of the screen.

Each device is assigned a random **16-bit ID**, displayed in the interface.

## Multicast Settings and Reuse Notes
By default, vanilla Godot does **not** expose the socket options required to allow multiple sockets to bind to the same port on the same machine.

This project optionally uses:

``` gdscript
_tx_peer.set_reuse_address_enabled(true)
_rx_peer.set_reuse_address_enabled(true)
_tx_peer.set_reuse_port_enabled(true)
_rx_peer.set_reuse_port_enabled(true)
```

These are available **only** in a [custom Godot build](https://github.com/not-my-username/godot/tree/udp-so-reuseaddress) where `PacketPeerUDP` exposes `SO_REUSEADDR` and `SO_REUSEPORT`.

**If using the standard Godot build:**  
Comment out those four lines in `start_node()`.  
The project will still work normally, you just won't be able to run multiple instances on the same machine for local discovery.

## License
MIT License  
(c) Liam Sherwin, 2025
