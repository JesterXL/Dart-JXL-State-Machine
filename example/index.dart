library examplejxlstatemachine;

import 'dart:html';
import 'dart:async';

import 'package:jxlstatemachine/jxlstatemachine.dart';

void main()
{
	print("main");
	example1();
}

void example1()
{
	StateMachine fsm = new StateMachine();
	fsm.addState("fire1");
	fsm.addState("fire2");
	fsm.addState("fire3");
	fsm.changes.listen((StateMachineEvent event)
	{
		print("event: " + event.type);
	});
	fsm.initialState = "fire1";
	
	Duration oneSecond = new Duration(seconds: 1);
	
	new Future.delayed(oneSecond, ()
	{
		fsm.changeState("fire2");
	});
	
	new Future.delayed(oneSecond, ()
	{
		fsm.changeState("fire3");
	});
}
