/**
* Name: surimi5km
* Author: LENOVO
*/

model surimi5km

global {
//    file shape_file_grid <- shape_file("../includes/smart5km/grid5km.shp");
    file shape_sub_grid  <- shape_file("../includes/smart5km/sub_shape5km.shp");
    
    // Correct Map Initialization
    map<string, map<string, list<int>>> id_grids_by_vessel <- [];
    
    list<string> months <- [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ];
    int current_month_index <- 0;
    geometry shape <- envelope(shape_sub_grid);

    init {
    // 1. Load Grid
 //   create cell from: shape_sub_grid with: [
 //       id :: string(read("id"))
 //   ];

    // 2. Load Sub-Grid Data
    create sub_grid from: shape_sub_grid with: [
        harbour_name       :: string(read("harbour")),
        vessel_name        :: string(read("CFR")),
        vessel_length      :: string(read("VL")),
        vessel_gear        :: string(read("Gear")),
        vessel_origharbour :: string(read("harbour")),
        id_grid            :: int(read("id")),
        MONTH              :: string(read("MONTH"))
    ];
    
    list<int> unique_ids <- remove_duplicates(sub_grid collect each.id_grid);

loop cid over: unique_ids {
    create cell {
        id <- string(cid);
        list<sub_grid> matching_subs <- sub_grid where (each.id_grid = cid);
        if !empty(matching_subs) {
            shape <- union(matching_subs collect each.shape);
            location <- shape.location;
        }
    }
}

    // 3. Create Harbours
    list<string> unique_harbours <- remove_duplicates(sub_grid collect each.harbour_name);

    loop h over: unique_harbours {
        create harbour {
            name <- h;
            list<sub_grid> my_subs <- sub_grid where (each.harbour_name = name);
            if !empty(my_subs) {
                location <- (union(my_subs collect each.shape)).location;
            }
        }
    }

    // 4. Create Vessels
    list<string> unique_vessel_names <- remove_duplicates(sub_grid collect each.vessel_name);

    loop v over: unique_vessel_names {
        create vessel {
            name <- v;
            list<sub_grid> v_data_list <- sub_grid where (each.vessel_name = name);
            if !empty(v_data_list) {
                sub_grid v_data <- first(v_data_list);

                vlength <- v_data.vessel_length;
                gear <- v_data.vessel_gear;
                origin_port <- v_data.vessel_origharbour;

                harbour home <- harbour first_with (each.name = origin_port);
                if (home != nil) {
                    location <- home.location;
                } else {
                    location <- (union(v_data_list collect each.shape)).location;
                }
            }
        }
    }

    // 5. Build lookup map
    loop s over: sub_grid {
        if !(id_grids_by_vessel contains_key s.vessel_name) {
            id_grids_by_vessel[s.vessel_name] <- [] as map<string, list<int>>;
        }
        map<string, list<int>> month_map <- id_grids_by_vessel[s.vessel_name];
        if !(month_map contains_key s.MONTH) {
            month_map[s.MONTH] <- [] as list<int>;
        }
        month_map[s.MONTH] << s.id_grid;
    }
    
    string this_month <- months[current_month_index];

ask vessel {
    map<string, list<int>> lookup <- id_grids_by_vessel[name];
    if (lookup != nil and lookup contains_key this_month) {
        list<int> ids <- lookup[this_month];
        if (!empty(ids)) {
            current_id_grid <- ids;
            current_grid_index <- 0;
        }
    }
}
}


reflex move_vessels_daily {
    ask vessel {
        if (!empty(current_id_grid)) {
            int next_id <- current_id_grid[current_grid_index];

            cell target_cell <- cell first_with (int(each.id) = next_id);
            if (target_cell != nil) {
                location <- target_cell.location;
            }

            current_grid_index <- current_grid_index + 1;

            if (current_grid_index >= length(current_id_grid)) {
                current_grid_index <- 0;
            }
        }
    }
}

reflex update_monthly_data when: (cycle > 0) and (cycle mod 30 = 0) {
    string this_month <- months[current_month_index];
    write "=== Month update: " + this_month;
    
    ask vessel {
        map<string, list<int>> lookup <- id_grids_by_vessel[name];
        if (lookup != nil and lookup contains_key this_month) {
            list<int> ids <- lookup[this_month];
            if (!empty(ids)) {
                current_id_grid <- ids;
                current_grid_index <- 0;
            } else {
                current_id_grid <- [];
                current_grid_index <- 0;
            }
        } else {
            current_id_grid <- [];
            current_grid_index <- 0;
        }
    }

    if (current_month_index = length(months) - 1) {
        write "End of year reached";
        do pause;
    } else {
        current_month_index <- current_month_index + 1;
    }
}

}

species cell {
    string id;
    int fishavailable <- 3000;
    aspect base { draw shape color: #blue border: #black; }
}

species sub_grid {
    string harbour_name; string vessel_name; string vessel_length;
    string vessel_gear; string vessel_origharbour; int id_grid; string MONTH;
}

species harbour {
    string name;
    aspect base {
        draw circle(2500) color: #red border: #black;
        draw name at: location + {0, 3000} color: #black font: font(10, #bold);
    }
}

species vessel skills: [moving] {
    string name; 
    string vlength; 
    string gear; 
    string origin_port;
    list<int> current_id_grid <- [];
    int current_grid_index <- 0;
    // Dynamic scale for drawing
    int vl -> (vlength = "VL1218") ? 1 : ((vlength = "VL1824") ? 2 : ((vlength = "VL2440") ? 3 : 1));

    aspect base {
        draw triangle(2000 * vl) color: #green border: #black rotate: 180;
    }
}

experiment surimi type: gui {
    output {
        monitor "Current Month" value: months[current_month_index];
        display surimi5km type: 2d {
            species cell aspect: base;
            species harbour aspect: base;
            species vessel aspect: base;
        }
    }
}

