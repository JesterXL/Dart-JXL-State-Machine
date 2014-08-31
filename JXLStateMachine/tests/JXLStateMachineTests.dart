library statemachine_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:JXLStateMachine/jxlstatemachine.dart';

void main()
{
	group('basic finite state machine tests', ()
	{
		StateMachine fsm = new StateMachine();
		
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
		
	});

}