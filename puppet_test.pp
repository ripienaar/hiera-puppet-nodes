class x($y) {
    exec{"/bin/echo 'inside x y is ${y}'":
        alias => x,
        refreshonly => true
    }
}

node "default" {
    hiera_node()
}
