Class {
	#name : #GtEpiceaPackagesHistoryBuilder,
	#superclass : #GtEpiceaHistoryBuilder,
	#category : #'GToolkit4Epicea-Model'
}

{ #category : #'accessing - grouping' }
GtEpiceaPackagesHistoryBuilder >> addChangeFor: anOmbuEntry toGroups: groupedByPackageName [ 
	(anOmbuEntry content isEpBehaviorChange or: [
		anOmbuEntry content isEpMethodChange ]) ifTrue: [
			self 
				addCodeEntityChange: anOmbuEntry 
				toPackageNamed: anOmbuEntry content gtAffectedPackageName
				inGroups: groupedByPackageName ]
]

{ #category : #adding }
GtEpiceaPackagesHistoryBuilder >> addCodeEntityChange: anOmbuEntry toPackageNamed: aPackageName inGroups: aDictionary [
	| packageGroup |
	
	packageGroup := aDictionary 
		at: aPackageName 
		ifAbsentPut: [ GtEpiceaEntriesGroup new ].
	
	packageGroup add: anOmbuEntry
]

{ #category : #'accessing - grouping' }
GtEpiceaPackagesHistoryBuilder >> addExtraEventForCategoryChangeFor: anOmbuEntry toGroups: groupedByPackageName [ 
	anOmbuEntry content class = EpBehaviorCategoryChange ifTrue: [
		self 
			addCodeEntityChange: anOmbuEntry
			toPackageNamed: anOmbuEntry content oldCategory
			inGroups: groupedByPackageName ]
]

{ #category : #'accessing - grouping' }
GtEpiceaPackagesHistoryBuilder >> addExtraEventForExtensionMethodFor: anOmbuEntry toGroups: groupedByPackageName [ 
	anOmbuEntry class = EpMethodModification ifFalse: [ ^ self ].
	
	"TODO"
]

{ #category : #actions }
GtEpiceaPackagesHistoryBuilder >> buildClassesHistoriesFor: aCollectionOfEntries forPackageNamed: aPackageName [
	| histories |
	
	histories := (GtEpiceaClassesHistoryBuilder forEntriesGroup: aCollectionOfEntries)
		classHistoryTypeName: GtEpiceaClassInPackageHistory name;
		buildHistory.
		
	histories do: [ :aClassHistory |
		aClassHistory targetPackageName: aPackageName ].
		
	^ histories
]

{ #category : #actions }
GtEpiceaPackagesHistoryBuilder >> buildHistory [
	| packagesHistory |
	packagesHistory := GtEpiceaPackageHistoriesGroup new.
	
	self groupedByPackageName associations do: [ :assoc |
		packagesHistory add: (self 
			createHistoryForPackageNamed: assoc key
			fromChanges: assoc value) ].
	
	^ packagesHistory
]

{ #category : #actions }
GtEpiceaPackagesHistoryBuilder >> createHistoryForPackageNamed: aPackageName fromChanges: aListOfChanges [ 
	^ GtEpiceaPackageHistory new
		targetPackageName: aPackageName;
		addClassHistories: (self 
			buildClassesHistoriesFor: aListOfChanges
			forPackageNamed: aPackageName)
]

{ #category : #'accessing - grouping' }
GtEpiceaPackagesHistoryBuilder >> groupedByPackageName [
	| groupedByPackageName |
	groupedByPackageName := Dictionary new.
	
	self entriesGroup do: [ :anOmbuEntry |
		self 
			addChangeFor: anOmbuEntry
			toGroups: groupedByPackageName.
		"self 
			addExtraEventForCategoryChangeFor: anOmbuEntry 
			toGroups: groupedByPackageName.
		self 
			addExtraEventForExtensionMethodFor: anOmbuEntry	
			toGroups: groupedByPackageName" ].
	
	^ groupedByPackageName
]