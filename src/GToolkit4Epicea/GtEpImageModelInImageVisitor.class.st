"
Iterate over the supplied {{gtClass:GtEpReplayImageModel}} and answer the minimum collection of entries required to recover the code state.
"
Class {
	#name : #GtEpImageModelInImageVisitor,
	#superclass : #Object,
	#instVars : [
		'image',
		'stream',
		'sequencedEntries',
		'earliestBehaviorDependency',
		'currentBehaviorModel'
	],
	#category : #'GToolkit4Epicea-Sequencer'
}

{ #category : #accessing }
GtEpImageModelInImageVisitor class >> image: aGtEpReplayImageModel [ 

	^ self new image: aGtEpReplayImageModel
]

{ #category : #sequencing }
GtEpImageModelInImageVisitor class >> sequencedEntriesFrom: aCollectionOfEntries [
	| visitor image replay |

	visitor := GtEpReplayEventVisitor new.
	visitor visitNodes: aCollectionOfEntries.
	image := visitor image.
	replay := self image: image.
	^ replay sequencedEntries.
]

{ #category : #private }
GtEpImageModelInImageVisitor >> alwaysIncludeBehaviorEvent: anEpEvent [
	"Answer a boolean indicating if the supplied event should always be included for replay"

	^ anEpEvent isEpBehaviorNameChange 
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> behaviorEntriesChangeRunningSystem: replayEntries [
	"Answer a boolean indicating whether the supplied behavior changes impact the running system."

	^ replayEntries isNotEmpty and:
		[ self behaviorModificationEntryDiffersFromCurrent: replayEntries last ]
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> behaviorModificationEntryDiffersFromCurrent: anOmEntry [
	"Renames can mean the superclass doesn't match, so it is ignored in the comparison."
	| index modificationString currentString |

	modificationString := anOmEntry content behaviorAffected definitionSource.
	index := modificationString indexOfSubCollection: 'subclass:'.
	index > 0 ifTrue:
		[ modificationString := modificationString copyFrom: index to: modificationString size ].

	currentString := (self environment at: "currentBehavior" anOmEntry content behaviorAffectedName 
			ifPresent: [ :behavior | behavior definitionString ]
			ifAbsent: [ '' ]).
	currentString ifNotEmpty:
		[ index := currentString indexOfSubCollection: 'subclass:'.
		self assert: index > 0.
		currentString := currentString copyFrom: index to: currentString size ].
	^ modificationString ~= currentString.
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> behaviorNameExists: aSymbol [

	^ self class environment includesKey: aSymbol.
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> commentEntryChangesRunningSystem: anOmEntry [
	"Answer a boolean indicating if the supplied entry will change the running system.
	Since the class may have been renamed, go back through previous names to find the current definition."
	| behaviorNames missingOriginal index newComment |

	newComment := anOmEntry content newComment ifNil: [ '' ].
	"Don't allow the string 'nil' to be set as the comment"
	newComment = 'nil' ifTrue: [ ^ false ].

	behaviorNames := OrderedCollection new.
	behaviorNames add: currentBehaviorModel behaviorAffectedName asSymbol.
	index := currentBehaviorModel previousNames size.
	missingOriginal := true.
	[ missingOriginal and: [ index > 0 ] ] whileTrue:
		[ | previousName |
		previousName := currentBehaviorModel previousNames at: index.
		behaviorNames add: previousName.
		previousName = anOmEntry content behaviorAffectedName 
			ifTrue: [ missingOriginal := false ]
			ifFalse: [ index := index - 1 ] ].

	behaviorNames do: [ :name |
		(self environment classOrTraitNamed: name) 	ifNotNil: [ :behavior | 
			^ behavior hasComment
				ifTrue: [ newComment ~= behavior comment ]
				ifFalse: [ true ] ] ].

	^ true
]

{ #category : #accessing }
GtEpImageModelInImageVisitor >> currentBehavior [
	"Answer the behavior with the same name as currentBehaviorModel, or nil"

	^ self environment classOrTraitNamed: currentBehaviorModel behaviorAffectedName.
]

{ #category : #accessing }
GtEpImageModelInImageVisitor >> environment [

	^ self class environment
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> eventHasImpact: anEpEvent [

	^ anEpEvent hasImpact
]

{ #category : #accessing }
GtEpImageModelInImageVisitor >> image [

	^ image
]

{ #category : #accessing }
GtEpImageModelInImageVisitor >> image: aGtEpReplayImageModel [

	image := aGtEpReplayImageModel.
	stream := Array new writeStream.
	self visitNode: image.
	sequencedEntries := stream contents.
	stream := nil.
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> isBehaviorAddition: anEpEvent [
	"Answer a boolean indicating whether the supplied event adds the behavior to the system"

	^ anEpEvent isEpClassAddition or: [ anEpEvent isEpClassModification or:
		[ anEpEvent isEpTraitAddition or: [ anEpEvent isEpTraitModification ] ] ].
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> isBehaviorRemoval: anEpEvent [
	"Answer a boolean indicating whether the supplied event removes the behavior from the system"

	^ anEpEvent isEpClassRemoval or: [ anEpEvent isEpTraitRemoval ].
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> isMethodAddition: anEpMethodChange [
	"Answer a boolean indicating whether the supplied event adds the behavior to the system"

	^ anEpMethodChange isEpMethodAddition or: [ anEpMethodChange isEpMethodModification ]
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> methodEntryChangesRunningSystem: anOmEntry [
	"Answer a boolean indicating whether the supplied entry changes the running system"
	| event |

	event := anOmEntry content.
	^ event isEpMethodRemoval
		ifTrue: [ event hasImpact ]
		ifFalse: [ self methodModificationEntryDiffersFromCurrent: anOmEntry ]
]

{ #category : #private }
GtEpImageModelInImageVisitor >> methodModificationEntryDiffersFromCurrent: anOmEntry [
	"Determine if the supplied method definition differs from what is currently in the system.  Check back through previous class names to see if the method is inherited through a rename."
	| isMetaSide behaviorNames missingOriginal index newSource |

	isMetaSide := anOmEntry content methodAffected isMetaSide.
	behaviorNames := OrderedCollection new.
	behaviorNames add: (isMetaSide
		ifTrue: [ currentBehaviorModel behaviorAffectedName, ' class' ]
		ifFalse: [ currentBehaviorModel behaviorAffectedName ]) asSymbol.
	index := currentBehaviorModel previousNames size.
	missingOriginal := true.
	[ missingOriginal and: [ index > 0 ] ] whileTrue:
		[ | previousName |
		previousName := currentBehaviorModel previousNames at: index.
		isMetaSide ifTrue: [ previousName := previousName, ' class' ].
		behaviorNames add: previousName.
		previousName = anOmEntry content behaviorAffectedName 
			ifTrue: [ missingOriginal := false ]
			ifFalse: [ index := index - 1 ] ].

	newSource := anOmEntry content methodAffectedSourceCode.
	behaviorNames do: [ :name |
		((self environment classOrTraitNamed: name)
			ifNotNil: [ :behavior | behavior compiledMethodAt: anOmEntry content methodAffectedSelector
					ifPresent: [ :method | ^ newSource ~= method sourceCode ]
					ifAbsent: [ nil ] ]
			ifNil: [ nil ]) ].

	^ true
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> protocolAdditionChangesRunningSystem: anOmEntry [
	"Answer a boolean indicating whether the supplied entry changes the running system"

	^ anOmEntry content hasImpact
]

{ #category : #testing }
GtEpImageModelInImageVisitor >> protocolRemovalChangesRunningSystem: anOmEntry [
	"Answer a boolean indicating whether the supplied entry changes the running system"

	^ anOmEntry content hasImpact
]

{ #category : #private }
GtEpImageModelInImageVisitor >> replayBehaviorFrom: aGtEpReplayBehaviorModel entries: entries [
	"Add the minimal set of change entries required.  
	Addition / Modification entries completely define the behavior.
	Behavior change entries depend on an existing definition.
	A full definition must exist before the earliestBehaviorDependency.
	Include an addition / modification before the earliestBehaviorDependency, if required.
	Include the last addition / modification and any subsequent refactoring.
	entries must be supplied in chronological order."
	| replayEntries index missingDefinition dependencyTime currentEntry endIndex |

	entries ifEmpty: [ ^ self ].

	replayEntries := OrderedCollection new.

	"Find the latest behavior definition that is prior to the earliest dependent entry"
	index := entries size.
	missingDefinition := true.
	dependencyTime := earliestBehaviorDependency gtTime.
	[ missingDefinition and: [ index > 0 ] ] whileTrue:
		[ currentEntry := entries at: index.
		((self isBehaviorAddition: currentEntry content) and:
			[ currentEntry gtTime < dependencyTime ]) ifTrue:
				[ missingDefinition := false ]
		ifFalse:
				[ index := index - 1 ] ].

	"If the entry found above matches the system it isn't required."
	((self isBehaviorAddition: currentEntry content) and:
		[ (self behaviorModificationEntryDiffersFromCurrent: currentEntry) not ]) ifTrue:
			[ index := index + 1 ].

	"Add the required entries"
	(index max: 1) to: entries size do: [ :i |
		replayEntries add: (entries at: i) ].

	"Intermedia additions / modifications can be removed.
	Find the last addition / modification."
	endIndex := replayEntries size.
	[ endIndex > 0 and: [ (self isBehaviorAddition: (replayEntries at: endIndex) content) not ] ]
		whileTrue: [ endIndex := endIndex - 1].
	endIndex - 1 to: 2 by: -1 do: [ :i |
		(self isBehaviorAddition: (replayEntries at: i) content) ifTrue:
			[ replayEntries removeIndex: i ] ].

	"If the changes have no impact on the system no need to add them"
	(self behaviorEntriesChangeRunningSystem: replayEntries) ifFalse: [ ^ self ].

	replayEntries do: [ :each | stream nextPut: each ].
]

{ #category : #private }
GtEpImageModelInImageVisitor >> replayBehaviorRemovalFrom: aGtEpReplayBehaviorModel [
	"Add the requried entries to remove the supplied behavior.
	If the source class (the name prior to renames) doesn't exist, there's nothing to do.
	If the behavior is removed we only need any renames and the final removal, method events can be ignored."
	| entries |

	aGtEpReplayBehaviorModel previousLives do: [ :previousBehavior |
		(self behaviorNameExists: previousBehavior originalBehaviorNameAffected) ifTrue:
			[ entries := previousBehavior entries.
			entries allButLastDo: [ :replayEntry | 
				replayEntry content isEpBehaviorNameChange ifTrue:
					[ stream nextPut: replayEntry ] ].
			stream nextPut: entries last ] ].

]

{ #category : #private }
GtEpImageModelInImageVisitor >> replayChangesFrom: aGtEpReplayBehaviorModel [
	"Replay the changes to the supplied behavior"

	self replayMethodEntriesFrom: aGtEpReplayBehaviorModel methods.
	self replayMethodEntriesFrom: aGtEpReplayBehaviorModel classSide methods.
	self replayBehaviorFrom: aGtEpReplayBehaviorModel entries: aGtEpReplayBehaviorModel entries.
	self replayProtocolEntriesFrom: aGtEpReplayBehaviorModel protocolChanges.
	self replayProtocolEntriesFrom: aGtEpReplayBehaviorModel classSide protocolChanges.
	self replayCommentEntriesFrom: aGtEpReplayBehaviorModel.
	
]

{ #category : #private }
GtEpImageModelInImageVisitor >> replayCommentEntriesFrom: aGtEpReplayBehaviorModel [
	"Only the latest comment entry counts"
	| latestCommentEntry |

	aGtEpReplayBehaviorModel hasCommentEntry ifFalse: [ ^ self ].

	latestCommentEntry := aGtEpReplayBehaviorModel latestCommentEntry.
	(self commentEntryChangesRunningSystem: latestCommentEntry) ifTrue:
		[ stream nextPut: aGtEpReplayBehaviorModel latestCommentEntry ].

]

{ #category : #private }
GtEpImageModelInImageVisitor >> replayMethodEntriesFrom: aGtEpReplayMethodModelCollection [
	"Methods refactorings can be ignored as the component events are also supplied.
	A rename will result in the source method being deleted.
	So only the latest change is required.
	Record the earliest behavior dependency for use while replaying behavior changes."

	aGtEpReplayMethodModelCollection do: [ :method | | entries lastEntry |
		entries := method entries.
		entries ifNotEmpty:
			[ lastEntry := entries last.
			(self methodEntryChangesRunningSystem: lastEntry) ifTrue:
				[ stream nextPut: lastEntry.
				lastEntry gtTime < earliestBehaviorDependency gtTime ifTrue:
					[ earliestBehaviorDependency := lastEntry ] ] ] ].
]

{ #category : #private }
GtEpImageModelInImageVisitor >> replayProtocolEntriesFrom: aGtEpReplayProtocolModelCollection [
	"Protocol entries either add an empty protocol or remove the protocol and all methods.
	So only the latest removal is required, and an addition if it comes after the removal."

	aGtEpReplayProtocolModelCollection do: [ :protocol | | entries lastRemoval lastAddition |
		entries := protocol entries.
		entries ifNotEmpty:
			[ entries do: [ :entry |
				entry content isEpProtocolAddition
					ifTrue: [ lastAddition := entry ]
					ifFalse: [ lastRemoval := entry ] ].
			lastRemoval ifNotNil:
				[ (self protocolRemovalChangesRunningSystem: lastRemoval) ifTrue:
					[ stream nextPut: lastRemoval ].
				(lastAddition isNotNil and: [ lastAddition gtTime > lastRemoval gtTime ]) ifTrue:
					[ (self protocolAdditionChangesRunningSystem: lastRemoval) ifTrue:
						[ stream nextPut: lastRemoval ] ] ] ] ].
]

{ #category : #accessing }
GtEpImageModelInImageVisitor >> sequencedEntries [

	^ sequencedEntries
]

{ #category : #visiting }
GtEpImageModelInImageVisitor >> visitBehaviorReplay: aGtEpReplayBehaviorModel [
	"Add the entries required for replay to the stream"

	currentBehaviorModel := aGtEpReplayBehaviorModel.
	"The latest event has to be earlier than now, set a dummy entry for comparison"
	earliestBehaviorDependency := OmEntry content: EpEvent new.
	earliestBehaviorDependency tags at: EpLog timeKey put: DateAndTime now.

	self replayBehaviorRemovalFrom: aGtEpReplayBehaviorModel.
	self replayChangesFrom: aGtEpReplayBehaviorModel.
	currentBehaviorModel := nil.
]

{ #category : #visiting }
GtEpImageModelInImageVisitor >> visitImageReplay: aGtEpReplayImageModel [

	aGtEpReplayImageModel behaviors do: [ :behavior |
		behavior accept: self ].
]

{ #category : #visiting }
GtEpImageModelInImageVisitor >> visitNode: aGtEpReplayImageModel [

	aGtEpReplayImageModel accept: self
]