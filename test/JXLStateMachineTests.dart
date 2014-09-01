library statemachine_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:jxlstatemachine/jxlstatemachine.dart';

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
		
		test('individual state gets enter callback', ()
		{
			bool called = false;
			Function onEnter = ()
			{
				called = true;
			};
			fsm.addState('main', enter: onEnter);
			fsm.initialState = 'main';
			expect(called, true);
		});
		
		test('parent states work', ()
		{
			fsm.addState('main');
			fsm.addState('child1', parent: 'main');
			fsm.addState('child2', parent: 'main');
			fsm.initialState = 'child1';
			expect(fsm.currentState.name, 'child1');
		});
		
		test('child state can go to sibling', ()
		{
			fsm.addState('main');
			fsm.addState('child1', parent: 'main');
			fsm.addState('child2', parent: 'main');
			fsm.initialState = 'child1';
			fsm.changeState('child2');
			expect(fsm.currentState.name, 'child2');
		});
		
		test('child state enter callback is called', ()
		{
			bool called = false;
			fsm.addState("main");
    		fsm.addState("defense", from: ["main"], 
    			enter: ()
    			{
    				called = true;
    			});
    		fsm.addState("row", from: ["main"]);
    		fsm.initialState = 'defense';
    		expect(called, true);
		});
		
		test('child state exit callback is called', ()
		{
			bool called = false;
			fsm.addState("main");
    		fsm.addState("defense", parent: 'main', 
    			exit: ()
    			{
    				called = true;
    			});
    		fsm.addState("row", parent: 'main');
    		fsm.initialState = 'defense';
    		fsm.changeState('row');
    		expect(called, true);
		});
		
	});

}