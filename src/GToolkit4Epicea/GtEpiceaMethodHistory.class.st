Class {
	#name : #GtEpiceaMethodHistory,
	#superclass : #GtEpiceaEntityHistory,
	#instVars : [
		'changes',
		'targetMethod',
		'latestChange',
		'initialChange'
	],
	#category : #'GToolkit4Epicea-Model'
}

{ #category : #'instance - accessing' }
GtEpiceaMethodHistory class >> forMethod: aTargetMethod withChanges: aCollectionOfEntries [
	^ self new 
		targetMethod: aTargetMethod;
		changes: (GtEpiceaEntriesGroup 
			withAll: (aCollectionOfEntries 
				sorted: [ :anEntry | anEntry gtTime] descending ))
]

{ #category : #accessing }
GtEpiceaMethodHistory >> changes [

	^ changes
]

{ #category : #accessing }
GtEpiceaMethodHistory >> changes: anObject [

	changes := anObject
]

{ #category : #'gt - extensions' }
GtEpiceaMethodHistory >> gtViewChangeDescriptionElements [
	^ self latestChange gtViewChangeDescriptionElements
]

{ #category : #'gt - extensions' }
GtEpiceaMethodHistory >> gtViewChangeHistoryChildren [
	^ self changes
]

{ #category : #'gt - extensions' }
GtEpiceaMethodHistory >> gtViewChangeIcon [
	self hasNoEffect ifTrue: [
		^ Smalltalk ui icons iconNamed: #windowMinimizeInactive ].
		
	self isLatestChangeRemoval ifTrue: [
		^ Smalltalk ui icons iconNamed: #changeRemoveIcon ].
	
	self isInitialChangeAddition ifTrue: [
		^ Smalltalk ui icons iconNamed: #changeAddIcon ].
	
	^ self latestChange gtViewChangeIcon
]

{ #category : #'gt - extensions' }
GtEpiceaMethodHistory >> gtViewEntriesListFor: aView [ 
	<gtView>
	
	^ aView forward 
		title: 'Entries List';
		priority: 10;
		object: [ self changes ];
		view: #gtItemsFor:
]

{ #category : #accessing }
GtEpiceaMethodHistory >> gtViewLatestChangeTime [ 
	^ self latestChange  gtTime
]

{ #category : #testing }
GtEpiceaMethodHistory >> hasNoEffect [
	^ self isInitialChangeAddition and: [ 
		self isLatestChangeRemoval ] 
]

{ #category : #accessing }
GtEpiceaMethodHistory >> initialChange [ 
	^ initialChange ifNil:  [
		initialChange := self changes initialChange ]
]

{ #category : #testing }
GtEpiceaMethodHistory >> isInitialChangeAddition [
	^ self initialChange content class = EpMethodAddition
]

{ #category : #testing }
GtEpiceaMethodHistory >> isLatestChangeRemoval [
	^ self latestChange content class = EpMethodRemoval
]

{ #category : #accessing }
GtEpiceaMethodHistory >> latestChange [ 
	^ latestChange ifNil:  [
		latestChange := self changes latestChange ]
]

{ #category : #acccessing }
GtEpiceaMethodHistory >> methodDisplayName [
	^ self targetMethod displayName
]

{ #category : #printing }
GtEpiceaMethodHistory >> printOn: aStream [
	super printOn: aStream.

	aStream
		parenthesize: [ 
			aStream << self methodDisplayName.
			aStream << ', '.
			aStream print: self changes size.
			aStream << ' '.
			aStream << ('change' asPluralBasedOn: self changes size) ]
]

{ #category : #acccessing }
GtEpiceaMethodHistory >> targetClassName [
	^ self targetMethod className
]

{ #category : #accessing }
GtEpiceaMethodHistory >> targetMethod [

	^ targetMethod
]

{ #category : #accessing }
GtEpiceaMethodHistory >> targetMethod: anObject [

	targetMethod := anObject
]