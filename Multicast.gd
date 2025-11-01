# Authors: (c) Liam Sherwin, 2025. MIT Licence

class_name MulticastDemo extends Control
## UDP Multicast device discovery demo


## The muticast group to use
const MCAST_GRP: String = "239.38.23.1"

## The port to open
const PORT: int = 3823

## Time in seconds to send out discovery messages
const DISCOVERY_TIME: float = 1.0


## The ItemList for displaying all discovred devices
@export var device_list: ItemList

## The ItemList for displaying all network interfaces and addresses
@export var interface_tree: Tree

## The Label to show this nodes ID
@export var self_id: Label

## The Timer to use for sending discovery messages
@export var discovery_timer: Timer


## All system network interfaces shown in the tree
var _displayed_interfaces: Dictionary[TreeItem, Dictionary] = {}

## The PacketPeerUDP for transmitting data to multicast
var _tx_peer: PacketPeerUDP = PacketPeerUDP.new()

## The PacketPeerUDP for receiving data from multicast
var _rx_peer: PacketPeerUDP = PacketPeerUDP.new()

## 16bit node it. No reason it needs to be 16 bit, just personal preference
var _node_id: int = randi_range(1, (1 << 16) - 1)

## List of all discovred devices
var _discovred_devices: Array[int] = []


## Ready
func _ready() -> void:
	interface_tree.create_item()
	interface_tree.set_column_expand(1, false)
	interface_tree.set_column_custom_minimum_width(1, 50)
	
	for interface: Dictionary in IP.get_local_interfaces():
		for address: String in interface.addresses:
			var address_item: TreeItem = interface_tree.create_item()
			
			address_item.set_text(0, address)
			address_item.set_text(1, interface.friendly if interface.friendly else interface.name)
			address_item.set_custom_color(1, Color.DIM_GRAY)
			
			_displayed_interfaces[address_item] = {"address": address, "interface": interface.name}
	
	self_id.set_text(str("Self: ", _node_id))


## Process
func _process(_p_delta: float) -> void:
	if _rx_peer.is_bound() and _rx_peer.get_available_packet_count():
		var id: Variant = _rx_peer.get_var()
		
		if id is int and id not in _discovred_devices:
			_discovred_devices.append(id)
			device_list.add_item(str(id))


## Starts discovery on this node with the given address and interface
func start_node(p_address: String, p_interface: String) -> void:
	print("Using address: ", p_address, " On interface: ", p_interface, "\n")
	
	## Following line are only valid when using my custom godot build with SO_REUSEADDR, and SO_REUSRPORT options exposed in the PacketPeerUDP class
	## See README for more details
	_tx_peer.set_reuse_address_enabled(true)
	_rx_peer.set_reuse_address_enabled(true)
	_tx_peer.set_reuse_port_enabled(true)
	_rx_peer.set_reuse_port_enabled(true)
	## -------
	
	var tx_error: Error = _tx_peer.bind(PORT, p_address)
	var rx_error: Error = _rx_peer.bind(PORT, MCAST_GRP)
	
	print("TX Bind: ", error_string(tx_error))
	print("RX Bind: ", error_string(rx_error))
	
	if tx_error or rx_error:
		return
	else:
		print()
	
	tx_error = _tx_peer.set_dest_address(MCAST_GRP, PORT)
	rx_error = _rx_peer.join_multicast_group(MCAST_GRP, p_interface)
	
	print("TX Config: ", error_string(tx_error))
	print("RX Config: ", error_string(rx_error))
	
	if tx_error or rx_error:
		return
	else:
		print("\nStartup sucessfull, beginning discovery.")
		discovery_timer.start(DISCOVERY_TIME)


## Sends a discovery to multicast
func send_discovery() -> void:
	if not _tx_peer.is_bound():
		return
	
	var tx_error: Error = _tx_peer.put_var(_node_id)
	
	print("Sent Discovery, status: ", error_string(tx_error))


## Called when the start button is pressed
func _on_start_pressed() -> void:
	var interface: Dictionary = _displayed_interfaces.get(interface_tree.get_selected(), {})
	
	if interface:
		start_node(interface.address, interface.interface)


## Called when the stop button is pressed
func _on_stop_pressed() -> void:
	_tx_peer.close()
	_rx_peer.close()
	device_list.clear()
	_discovred_devices.clear()
