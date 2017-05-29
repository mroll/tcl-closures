package require TclOO
source jbroo.tcl


set TEST 0

# create a list of @key, $value pairs for use with [string map]
proc mapvars { args } {
    foreach v $args { lappend res @$v; lappend res [uplevel [list set $v]] }
    set res
}

proc callerlvl { } { expr { [info level] - 2 } }

proc defbody { closedvars args body } {
    set context [mapvars closedvars args body]
    string map $context {
        foreach var {@closedvars} { variable _$var; accessor _$var }

        constructor { args } {
            foreach var {@closedvars} arg $args  {
                upvar #[callerlvl] $arg [self namespace]::_$var
            }
        }

        method unknown { @args } {
            foreach var {@closedvars} { set $var [set _$var] }
            set res [eval {@body}]
            foreach var {@closedvars} { set _$var [set $var] }
            return $res
        }
    }
}

proc def { name closedvars lambda } {
    if { [llength $lambda] eq 1 } {
        set args { _ }
        set body [lindex $lambda 0]
    } else {
        set args [lindex $lambda 0]
        set body [lindex $lambda 1]
    }

    oo::class create ::$name [defbody $closedvars $args $body]
}



## ---------------------------------------- ##


if { $TEST } {
    def acc n {{ incr n $_ }}
    def dec n {{ incr n -$_ }}
    
    def lacc l {{
            if { [llength $_] ne [llength $l] } {
                    puts "list lengths must match"
                    return }
            set l [lmap x $_ y $l { expr { $x + $y } }]
        }}
    
    
    set d 4
    set s {1 2 3 4 5}
    
    lacc create baz s
    puts [baz {1 2 3 4 5}]
    puts [baz {1 2 3 4 5}]
    puts $s
    
    acc create foo d
    acc create foo2 d
    dec create bar d
    
    foo 2
    puts $d
    puts [foo 0]
    puts $d
    
    foo2 3
    puts $d
    
    bar 2
    bar 3
    puts [bar 0]
    puts $d

}
