Class {
	#name : #BaselineOfGToolkit4Changes,
	#superclass : #BaselineOf,
	#category : #BaselineOfGToolkit4Changes
}

{ #category : #baseline }
BaselineOfGToolkit4Changes >> baseline: spec [

	<baseline>
	spec for: #common do: [ 
		spec
			baseline: 'Brick'
			with: [ spec repository: 'github://feenkcom/Brick:main/src' ].
		spec package: 'GToolkit4Epicea' with: [ spec requires: #( 'Brick' ) ] ]
]