/**
* Name: surimi
* Based on the internal empty template. 
* Author: LENOVO
*/
model surimi

global {
    file shape_file_cells <- shape_file("../includes/DataNEW/coord_cells.shp"); //OK
    file shape_file_ports <- shape_file("../includes/DataNEW/coords_port.shp"); //OK
    file vessel_csv <- csv_file("../includes/DataNEW/combined_vessel.csv", ",", true); // OK
    file visits_csv <- csv_file("../includes/DataNEW/vessel_by_cell.csv", ",", true); //OK
    float step <- 1#day; // day
    bool show_routes <- false;   // set to true to show routes
    int meterperhour <- 100 ;
    int capital_hour <- 300  #day;
    int sd_hourfishing <- 0;
    float step_dist <- meterperhour #m / #h ;
 
    reflex check_time {
        // 'time' is a built-in variable (cycle * step)
        write "Total simulated time: " + time + " days";
    }
    geometry shape <- envelope(shape_file_cells);
    
    // cell id -> cell agent
    map<string, cell> cell_by_id <- map([]);
    // MMSI -> list of visited cell ids (in CSV order)
    map<string, list<string>> visits_by_mmsi <- map([]);
    
 
    

 init {
    create cell from: shape_file_cells with:[id:string(read("id"))];
    ask cell {
    cell_by_id[id] <- self;
    }
    
    
    create port from: shape_file_ports with:[name:: string(read("port"))];
    write "ports created = " + length(port);
    
    create visit from: visits_csv with: [
    mmsi:: string(read("MMSI")),
    cell_id:: string(read("id"))
];

ask visit {
    if (visits_by_mmsi contains_key mmsi) {
        visits_by_mmsi[mmsi] <- visits_by_mmsi[mmsi] + [cell_id];
    } else {
        visits_by_mmsi[mmsi] <- [cell_id];
    }
}

    create vessel from: vessel_csv with: [
      name:: string(read("MMSI")),
      vlength:: string(read("vlength")),
      origin_port:: string(read("port")),
      gear:: string(read("gear"))
    ]{
  if (vlength = "VL1218") { vl <- 1; }
  else if (vlength = "VL1824") { vl <- 2; }
  else if (vlength = "VL2440") { vl <- 3; }
  else { vl <- 1; }
  }
    
   
    ask vessel {
    port p <- one_of(port where (each.name = origin_port));
    location <- p.location + { rnd(-3000, 3000), rnd(-3000, 3000) };
    }
    
    ask vessel {
    if (visits_by_mmsi contains_key name) {
        visited_cell_ids <- visits_by_mmsi[name];
    } else {
        visited_cell_ids <- [];
        // optional debug
        // write "No visited cells for MMSI=" + name;
    }
}
    // build the route immediately (so it shows at step 0)
ask vessel { do compute_route; }
   
}

reflex update_world {
 //   	write "Current cycle: " + cycle;
 // time = cycle * steps [in secondi]
    	
   if ( time = 15552000 ) { // capital_hour <= 0 
    		do pause;
    		}
    	}
 
}


species cell {
	string id;
	int fishavailable <- 3000; // rnd(0, 1000);
    aspect base {
    //draw shape color: #blue border: #black width: 1;
	draw shape color: #blue border: #black width: 1; // rgb(0, 0, fishavailable / 2) border: #black width: 1;
    }
}

species port {
    string name;
    aspect base {
        draw circle(5000) color: #red border: #black;

        if (name = "CHIAVARI") {
            draw name at: location + {1000, 1000} color: #black;
        } else {
            draw name at: location + {5000, 5000} color: #black;
        }
    }
}

species vessel skills:[moving]{
    string name <- "";
    string vlength <- "";
    string origin_port <- "";
    int vl <- 1;
    string gear <- "";
    int route_index <- 0;
    int route_dir <- 1;        // +1 forward, -1 backward
    bool moving_route <- true;
    int storedfish <- 0;
    int fishcap <- rnd(1, 3); 
    int hourfished_threshold <-  int(max(0.0, gauss_rnd(100.0, sd_hourfishing))) #hour;
//    int hourfished__used <- 0;

    list<string> visited_cell_ids <- [];
    list<point> route_pts <- [];

//    int route_index <- 0;         // which waypoint we’re heading to
//    bool moving_route <- true;    // switch to start/stop

//    float step_dist <- 2000.0;    // distance moved each step (tune to your CRS)

    action compute_route {
        route_pts <- [location];
        loop cid over: visited_cell_ids {
            if (cell_by_id contains_key cid) {
                route_pts <- route_pts + [cell_by_id[cid].location];
            }
        }
        route_index <- 0;
    }

reflex follow_route when: moving_route {
    if length(route_pts) <= 1 {
        moving_route <- false;
    } else {
        float remaining_dist <- step_dist * step;

        loop while: (remaining_dist > 0 and route_index < length(route_pts) - 1) {
            point target <- route_pts[route_index + 1];

            float dx <- target.x - location.x;
            float dy <- target.y - location.y;
            float d <- sqrt(dx * dx + dy * dy);

            if (d <= remaining_dist) {
                location <- target;
                route_index <- route_index + 1;
                remaining_dist <- remaining_dist - d;
            } else {
                float ratio <- remaining_dist / d;
                location <- {location.x + dx * ratio, location.y + dy * ratio};
                remaining_dist <- 0.0;
            }
        }

        if (route_index >= length(route_pts) - 1) {
            moving_route <- false;
        }
    }
}

    // Move along route_pts in order
// reflex follow_route when: moving_route {
//     if length(route_pts) > 1 {

        // stop if we are already at the last point
//         if route_index >= (length(route_pts) - 1) {
//             moving_route <- false;
//         } else {

//             point target <- route_pts[route_index + 1];

            // move toward next target
//             do goto target: target speed: step_dist;

            // manual distance check
//             float dx <- location.x - target.x;
//             float dy <- location.y - target.y;
//             float d <- sqrt(dx * dx + dy * dy);

            // if close enough, go to next waypoint
//             if (d <= 1000 #m) {
//                 route_index <- route_index + 1;
//             }
//         }

//     } else {
//         moving_route <- false;
//     }
// }

            // distance check (point, point) — works in your build
//            if (distance_between(location, target) <= step_dist) {
//                route_index <- route_index + 1;
//            }
//        }
//    } else {
//        moving_route <- false;
//    }

reflex collect_fish when: moving_route {
    cell best <- nil;
    float best_d <- 1e30;

    // find nearest cell by manual distance to cell.location
    ask cell {
        float dx <- location.x - myself.location.x;
        float dy <- location.y - myself.location.y;
        float d <- sqrt(dx * dx + dy * dy);

        if (d < best_d) {
            best_d <- d;
            best <- self;
        }
    }

    // collect from nearest // cell mean(vessel collect each.hourfished_threshold)
    if best != nil and best.fishavailable > 0 {
    	if hourfished_threshold > 0 {
        best.fishavailable <- best.fishavailable - 1 ;
        storedfish <- storedfish + 1;
        hourfished_threshold <- hourfished_threshold - 1 #hour;
        capital_hour <- capital_hour -  1 #hour;
        
        }
        }
    }






    aspect base {
        draw triangle(5000 * vl) color: #green border: #black rotate: 180;

        if show_routes and length(route_pts) > 1 {
            draw polyline(route_pts) color: #black width: 3;
        }
    }
}


species visit {
    string mmsi <- "";
    string cell_id <- "";
}


experiment surimi type: gui {

    parameter "Show vessel routes" var: show_routes category: "Display";
//    parameter "Step distance (movement speed)" var: step_dist category: "Movement";
    parameter "Meter per hour" var: meterperhour category: "Vessels Behavior";
    parameter "SD Hoursfishing" var: sd_hourfishing category: "Vessels Behavior";
    parameter "Capital Hours" var: capital_hour category: "Policy Setting";
     
    output {

        display surimi type: 2d {
            species cell aspect: base;
            species port aspect: base;
            species vessel aspect: base;
        }

        display "Amount" {
            chart "Fish collected" type: series {
                data "Cells available fish" value: sum(cell collect each.fishavailable);
                data "Vessels collected fish" value: sum(vessel collect each.storedfish);
            }
        }

        monitor "Cells available fish" value: sum(cell collect each.fishavailable);
        monitor "Vessels collected fish" value: sum(vessel collect each.storedfish);
        monitor "Capital Collective Hours" value: capital_hour;
    }
}