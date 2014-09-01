library statemachine_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:JXLStateMachine/jxlstatemachine.dart';

void main()
{
	
	group('basic finite state machine', ()
	{
		StateMachine fsm;
		
		setUp(()
		{
			fsm = new StateMachine();
		});
		
		tearDown(()
		{
			fsm = null;
		});
		
		test('can add a state', ()
		{
			fsm.addState('fire1');
			expect(fsm.currentState, null);
		});
		
		test('can add a state and make it the current', ()
		{
			State defaultState = fsm.addState('defaultState');
			fsm.initialState = 'defaultState';
			expect(fsm.currentState, defaultState);
		});
		
		test('can add multiple states and make the 1st current', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2');
			fsm.addState('fire3');
			fsm.initialState = 'fire1';
			expect(fsm.currentState.name, 'fire1');
		});
		
		test('can move from one state to the other', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2');
			fsm.initialState = 'fire1';
			fsm.changeState('fire2');
			expect(fsm.currentState.name, 'fire2');
		});
		
		test('can move from one state to the next and back again', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2');
			fsm.initialState = 'fire1';
			fsm.changeState('fire2');
			fsm.changeState('fire1');
			expect(fsm.currentState.name, 'fire1');
		});
		
		test('can move from one state to the next and back again with 3 states', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2');
			fsm.addState('fire3');
			fsm.initialState = 'fire1';
			fsm.changeState('fire2');
			fsm.changeState('fire3');
			expect(fsm.currentState.name, 'fire3');
		});
		
	});
	
	group('intermediate finite state machine', ()
	{
		StateMachine fsm;
		StreamSubscription subscription;
		
		setUp(()
		{
			fsm = new StateMachine();
		});
		
		tearDown(()
		{
			fsm = null;
			if(subscription != null)
			{
				subscription.cancel();
				subscription = null;
			}
		});
		
		test('can go to * states from any state', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2', from: ["*"]);
			fsm.initialState = 'fire1';
			fsm.changeState('fire2');
			expect(fsm.currentState.name, 'fire2');
		});
		
		test('successfully fires a transition denied event for non-from events', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2', from: ["moocow"]);
			fsm.initialState = 'fire1';
			bool called = false;
			subscription = fsm.changes
			.where((StateMachineEvent event)
			{
				return event.type == StateMachineEvent.TRANSITION_DENIED;
			})
			.listen((StateMachineEvent event)
			{
				called = true;
			});
			Function callback = expectAsync((bool success) => success);
			fsm.changeState('fire2').then(callback);
			expect(called, true);
		});
		
		test('successfully fires a transition complete event for approved events', ()
		{
			fsm.addState('fire1');
			fsm.addState('fire2', from: ["fire1"]);
			fsm.initialState = 'fire1';
			bool called = false;
			subscription = fsm.changes
			.where((StateMachineEvent event)
			{
				return event.type == StateMachineEvent.TRANSITION_COMPLETE;
			})
			.listen((StateMachineEvent event)
			{
				called = true;
			});
			Function callback = expectAsync((bool success) => success);
			fsm.changeState('fire2').then(callback);
			expect(called, true);
		});
	});

}