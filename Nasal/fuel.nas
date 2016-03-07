
# ==================================== timer stuff ===============================

# set the update period

UPDATE_PERIOD = 0.3;

# set the timer for the selected function

var registerTimer = func {

	settimer(arg[0], UPDATE_PERIOD);

} # end function 

# ======================================= fuel tank stuff ===================================

# operate fuel cocks

var openCock=func{

	var cock=getprop("controls/engines/engine/fuel-cock/lever");

	if (cock < 1){
		cock = cock +1;
		setprop("controls/engines/engine/fuel-cock/lever",cock);
		adjustCock()
	}

}#end func

var closeCock=func{

	var cock = getprop("controls/engines/engine/fuel-cock/lever");

	if (cock > 0){
		cock = cock - 1;
		setprop("controls/engines/engine/fuel-cock/lever",cock);
		adjustCock()
	}

}#end func


# adjust fuel cocks

var adjustCock = func{

	var lever=getprop("controls/engines/engine/fuel-cock/lever");

	if (lever == 0){
		setprop("consumables/fuel/tank[0]/selected",0);
		setprop("consumables/fuel/tank[1]/selected",0);
		setprop("consumables/fuel/tank[2]/selected",0);
	}
	else{
		setprop("consumables/fuel/tank[0]/selected",1);
		setprop("consumables/fuel/tank[1]/selected",1);
		setprop("consumables/fuel/tank[2]/selected",0);
	}


}#end func

# tranfer fuel

fuelTrans = func {

	var amount = 0;
	var maxFlowRate = 1;

	if(getprop("/sim/freeze/fuel")) { return registerTimer(fuelTrans); }

	capacityFwd = getprop("consumables/fuel/tank[0]/capacity-gal_us");
	if(capacityFwd == nil) { capacityFwd = 0; }

	var levelFwd = getprop("consumables/fuel/tank[0]/level-gal_us");
	if(levelFwd == nil) { levelFwd = 0; }

	var levelSaddle = getprop("consumables/fuel/tank[2]/level-gal_us");
	if(levelSaddle == nil) { levelSaddle = 0; }

	var levelDropStbd = getprop("consumables/fuel/tank[3]/level-gal_us");
	if(levelDropStbd == nil) { levelDropStbd = 0; }

	var levelDropPort = getprop("consumables/fuel/tank[4]/level-gal_us");
	if(levelDropPort == nil) { levelDropPort = 0; }	

	if ( capacityFwd > levelFwd and levelDropStbd > 0){
		amount = capacityFwd - levelFwd;
		if (amount > levelDropStbd) {
			amount = levelDropStbd;
		}
		if (amount > maxFlowRate) {
			amount = maxFlowRate;
		}
		levelDropStbd = levelDropStbd - amount/2;
		levelDropPort = levelDropPort - amount/2;
		levelFwd = levelFwd + amount;
		setprop( "consumables/fuel/tank[3]/level-gal_us",levelDropStbd);
		setprop( "consumables/fuel/tank[4]/level-gal_us",levelDropPort);
		setprop( "consumables/fuel/tank[0]/level-gal_us",levelFwd);
	}

	if ( capacityFwd > levelFwd and levelSaddle > 0){
		amount = capacityFwd - levelFwd;
		if (amount > levelSaddle) {
			amount = levelSaddle;
		}
		if (amount > maxFlowRate) {
			amount = maxFlowRate;
		}
		levelSaddle = levelSaddle - amount;
		levelFwd = levelFwd + amount;
		setprop( "consumables/fuel/tank[2]/level-gal_us",levelSaddle);
		setprop( "consumables/fuel/tank[0]/level-gal_us",levelFwd);
	}

#print("Upper: ",levelSaddle, " Lower: ",levelFwd);
#print( " Amount: ",amount);

	registerTimer(fuelTrans);

} # end funtion fuelTrans    

# fire it up

registerTimer(fuelTrans);

# ========================== end fuel stuff ======================================

#================================== Droptanks ================================
print("droptanks starting");
var droptank_node = props.globals.getNode("sim/ai/aircraft/impact/droptank", 1);
var ext_force_stbd_node = props.globals.getNode("sim/ai/ballistic/force", 1);
ext_force_stbd_node.getChild("force-lb", 0, 1).setDoubleValue(0);
ext_force_stbd_node.getChild("force-azimuth-deg", 0, 1).setDoubleValue(0);
ext_force_stbd_node.getChild("force-elevation-deg", 0, 1).setDoubleValue(0);
ext_force_stbd_node.getChild("force-norm", 0, 1).setDoubleValue(0);

var ext_force_port_node = props.globals.getNode("sim/ai/ballistic/force[1]", 1);
ext_force_port_node.getChild("force-lb", 0, 1).setDoubleValue(0);
ext_force_port_node.getChild("force-azimuth-deg", 0, 1).setDoubleValue(0);
ext_force_port_node.getChild("force-elevation-deg", 0, 1).setDoubleValue(0);

var ext_force_extra_node = props.globals.getNode("sim/ai/ballistic/force[2]", 1);
ext_force_extra_node.getChild("force-lb", 0, 1).setDoubleValue(0);
ext_force_extra_node.getChild("force-azimuth-deg", 0, 1).setDoubleValue(0);
ext_force_extra_node.getChild("force-elevation-deg", 0, 1).setDoubleValue(90);

var pitch_node = props.globals.getNode("orientation/pitch-deg", 1);
var hdg_node = props.globals.getNode("orientation/heading-deg", 1);

var droptanks = func(n) {
	var droptank = droptank_node.getValue();
	var node = props.globals.getNode(n.getValue(), 1);
	print (" droptank ", droptank, " lon " , node.getNode("impact/longitude-deg").getValue(),);
	geo.put_model("Aircraft/juef128/Models/droptank-hot.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.25,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
}

setlistener("sim/ai/aircraft/impact/droptank", droptanks);

var ext_force_stbd = func {
    if(ext_force_stbd_node.getChild("force-lb", 0, 1).getValue() != 0){
       ext_force_stbd_node.getChild("force-lb", 0, 1).setDoubleValue(0);
       ext_force_stbd_node.getChild("force-norm", 0, 1).setDoubleValue(0);
       return;
    } else {
        ext_force_stbd_node.getChild("force-lb", 0, 1).setDoubleValue(1000);
        ext_force_stbd_node.getChild("force-azimuth-deg", 0, 1).setDoubleValue(hdg_node.getValue());
        ext_force_stbd_node.getChild("force-elevation-deg", 0, 1).setDoubleValue(pitch_node.getValue()-90);
        ext_force_stbd_node.getChild("force-norm", 0, 1).setDoubleValue(1);
        setprop("ai/models/ballistic[1]/controls/slave-to-ac",0);
        setprop("ai/models/ballistic[3]/controls/slave-to-ac",0);
        settimer(ext_force_stbd,0.75);
    }
}

setlistener( "controls/armament/station[1]/jettison-all", ext_force_stbd);

var ext_force_port = func {
    if(ext_force_port_node.getChild("force-lb", 0, 1).getValue() != 0){
       ext_force_port_node.getChild("force-lb", 0, 1).setDoubleValue(0);
       ext_force_port_node.getChild("force-norm", 0, 1).setDoubleValue(0);
       return;
    } else {
        ext_force_port_node.getChild("force-norm", 0, 1).setDoubleValue(1);
        ext_force_port_node.getChild("force-lb", 0, 1).setDoubleValue(1000);
        ext_force_port_node.getChild("force-azimuth-deg", 0, 1).setDoubleValue(hdg_node.getValue());
        ext_force_port_node.getChild("force-elevation-deg", 0, 1).setDoubleValue(pitch_node.getValue()-90);
        ext_force_port_node.getChild("force-norm", 0, 1).setDoubleValue(1);
#        print ("elevation ", ext_force_port_node.getChild("force-elevation-deg", 0, 1).getValue());
        setprop("ai/models/ballistic[0]/controls/slave-to-ac",0);
        setprop("ai/models/ballistic[2]/controls/slave-to-ac",0);
        settimer(ext_force_port,0.75);
    }
}

setlistener( "controls/armament/station[0]/jettison-all", ext_force_port);

print("droptanks running");

setlistener("/sim/signals/fdm-initialized", func {
    var droptank_set_node = props.globals.getNode("sim/stores/load-tanks", 1);
    droptank_set_node.setBoolValue(1);
    var droptank_set1_node = props.globals.getNode("sim/stores/load-tanks[1]", 1);
    droptank_set1_node.setBoolValue(1);
    print ("loading droptanks");
	}
);

# end 
