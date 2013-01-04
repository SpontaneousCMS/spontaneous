
background_mode :simultaneous

simultaneous_connection ENV["SIMULTANEOUS_SOCKET"]
spontaneous_binary      ENV["SPONTANEOUS_BINARY"]

server_connection       ENV["SPONTANEOUS_SERVER"]

# used by publishing mech to determine a restart strategy
handler                 :unicorn
after_publish_restart   ENV["POST_PUBLISH_COMMAND"]

