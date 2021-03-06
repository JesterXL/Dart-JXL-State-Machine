library jxlstatemachine;

import 'dart:async';
import 'package:observe/observe.dart';

class State
{
	String _name;
	List<String> _from;
	Function _enter;
	Function _exit;
	State _parent;
	
	StreamController _streamController;
	Stream _changes;
	
	String get name => _name;
	List<String> get from => _from;
	Function get enter => _enter;
	Function get exit => _exit;
	State get parent => _parent;
	Stream get changes => _streamController.stream;
	
	ObservableList<State> children = new ObservableList<State>();
	
	set parent(State parentState)
	{
		_parent = parentState;
		_streamController.add(new StateMachineEvent(StateMachineEvent.PARENT_CHANGED));
		if(_parent != null)
		{
			_parent.children.add(this);
		}
	}
	
	State get root
	{
		State currentParentState = parent;
		if(currentParentState != null)
		{
			while(currentParentState.parent != null)
			{
				currentParentState = currentParentState.parent;
			}
		}
		return currentParentState;
	}
	
	List<State> get parents
	{
		List<State> parents = new List<State>();
		State currentParentState = parent;
		if(currentParentState != null)
		{
			parents.add(currentParentState);
			while(currentParentState != null)
			{
				currentParentState = currentParentState.parent;
				if(currentParentState != null)
				{
					parents.add(currentParentState);
				}
				else
				{
					break;
				}
			}
		}
		return parents;
	}
	
	bool isParentState(String stateName)
	{
		List<State> currentParents = parents;
		if(currentParents.length > 0)
		{
			currentParents.forEach((parentState)
			{
				if(parentState.name == stateName)
				{
					return true;
				}
			});
		}
		return false;
	}
	
	State(String this._name, {List<String> from: null, 
						Function enter: null, 
						Function exit:null, 
						State parent:null})
	{
		_name = name;
		// NOTE: We set it to * to ensure it's never null. * means "from anywhere"
		if(from == null)
		{
			_from = new List<String>();
			_from.add("*");
		}
		else
		{
			_from = from;
		}
		_enter = enter;
		_exit = exit;
		if(parent != null)
		{
			_parent = parent;
			_parent.children.add(this);
		}
	}
}

class StateMachine
{
	
	
	State _currentState;
	State _currentParentState;
	List<State> _currentParentStates;
	StreamController _streamController = new StreamController.broadcast(sync: true);
	Stream _changes;
	
	State get currentState => _currentState;
	Stream get changes => _streamController.stream;
	
	Map<String, State> states = new Map<String, State>();
	
	set initialState(String startStateName)
	{
		State initial = states[startStateName];
		_currentState = initial;
		State root = initial.root;
		if(root != null)
		{
			_currentParentStates = initial.parents;
			_currentParentStates.forEach((State parentState)
			{
				if(parentState.enter != null)
				{
					// TODO: make event class
					// local event = {name = "onEnterState", target = self, toState = stateName, entity = self.entity}
					//event.currentState = parentState.name;
					parentState.enter();
				}
			});
		}
		
		if(initial.enter != null)
		{
			// TODO: make event class
			initial.enter();
		}
		
		// TODO: dispatch transition complete... man... these should all be streams, eff me
		// local outEvent = {name = "onTransitionComplete", target = self, toState = stateName}
		
		_streamController.add(new StateMachineEvent(StateMachineEvent.STATE_CHANGE));
	}
	
	set currentState(State state)
	{
		_currentState = state;
	}
	
	// NOTE: I'm aware the map is flat, and I don't support multiple states of the same name.
	// TODO: fix if you care, I don't. I believe Dart Map throws error if you attempt set
	// an already existing State.
	State addState(String stateName, {List<String> from: null, 
										Function enter: null, 
										Function exit:null, 
										String parent:null})
	{
		State parentState = null;
		if(parent != null)
		{
			parentState = states[parent];
		}
		State newState = new State(stateName,
									from: from,
									enter: enter,
									exit: exit,
									parent: parentState);
		states[stateName] = newState;
		return newState;
	}
	
	bool canChangeStateTo(String stateName)
	{
		State targetToState = states[stateName];
		int score = 0;
		int win = 2;
		
		if(stateName != currentState.name)
		{
			score++;
		}
		
		// NOTE: Lua via State.inFrom was walking up one parent if from was null... why?
		if(targetToState.from != null)
		{
			if(targetToState.from.contains(_currentState.name) == true)
			{
				score++;
			}
			
			if(targetToState.from.contains("*") == true)
			{
				score++;
			}
		}
		
		if(currentState != null && currentState.parent != null)
		{
			if(currentState.parent.name == stateName)
			{
				score++;
			}
		}
		
		if(targetToState.from == null)
		{
			score++;
		}
		
		if(score >= win)
		{
			return true;
		}
		else
		{
			return false;
		}
		
	}
	
	List<int> findPath(String stateFrom, String stateTo)
	{
		State fromState = states[stateFrom];
		int c = 0;
		int d = 0;
		List<int> path = new List<int>();
		while(fromState != null)
		{
			d = 0;
			State toState = states[stateTo];
			while(toState != null)
			{
				if(fromState == toState)
				{
					path.add(c);
					path.add(d);
					return path;
				}
				d++;
				toState = toState.parent;
			}
			c++;
			fromState = fromState.parent;
		}
		path.add(c);
		path.add(d);
		return path;
	}

	Future changeState(String stateName)
	{
		Completer completer = new Completer();
		if(canChangeStateTo(stateName) == false)
		{
			_streamController.add(new StateMachineEvent(StateMachineEvent.TRANSITION_DENIED));
			completer.complete(false);
			return completer.future;
		}
		
		List<int> path = findPath(_currentState.name, stateName);
		if(path[0] > 0)
		{
//			local exitCallback = {name = "onExitState",
//            									target = self,
//            									toState = stateTo,
//            									fromState = state}
			if(_currentState.exit != null)
			{
				//exitCallback.currentCallback = _currentState;
				_currentState.exit();
			}
			
			_currentParentState = _currentState;
			
			int p = 0;
			while(p < path[0])
			{
				_currentParentState	= _currentParentState.parent;
				if(_currentParentState != null && _currentParentState.exit != null)
				{
					// exitCallback.currentState = _currentParentState.parentState.name;
					_currentParentState.exit();
				}
				p++;
			}
		}
		
		State toState = states[stateName];
		State oldState = _currentState;
		_currentState = toState;
		
		if(path[1] > 0)
		{
//			local enterCallback = {name = "onEnterState",
//            									target = self,
//            									toState = stateTo,
//            									fromState = oldState,
//            									entity = self.entity}
			
			if(toState.root != null)
			{
				_currentParentStates = toState.parents;
				int secondPath = path[1];
				int k = secondPath - 1;
				while(k >= 0)
				{
					State theCurrentParentState = _currentParentStates[k];
					if(theCurrentParentState != null && theCurrentParentState.enter != null)
					{
						// enterCallback.currentState = theCurrentParentState.name;
						theCurrentParentState.enter();
					}
					k--;
				}
			}
			
			if(toState.enter != null)
			{
				// enterCallback.currentState = toState.name;
				toState.enter();
			}
		}
		
//		local outEvent = {name = "onTransitionComplete",
//        							target = self,
//        							fromState = oldState,
//        							toState = stateTo}
//        		self:dispatchEvent(outEvent)
		_streamController.add(new StateMachineEvent(StateMachineEvent.TRANSITION_COMPLETE));
		completer.complete(true);
		return completer.future;
	}
	
}

class StateMachineEvent
{
	
	static const STATE_CHANGE = "stateChange";
	static const TRANSITION_COMPLETE = "transitionComplete";
	static const TRANSITION_DENIED = "transitionDenied";
	
	// State events
	static const PARENT_CHANGED = "parentChanged";
	
	String _type;
	
	String get type => _type;
	
	StateMachineEvent(String this._type)
	{	
	}
	
}


