;;It is not clear how Sentaurus handles PolySi, so it is recommoned to dope the N++ electrode/Bulk interface, instead of filling the N++ Cylinder with PolySi
;; Single Side 3D for ITk
;; When doping the N electrode, the Poly and the Columnar have to be doped seperately
;; Define geometry
(define TopOxide -0.3)
(define MidOxide -0.5)
(define BtmOxide -1)
(define PolyStartY (+ BtmOxide MidOxide))
(define PolyCenterY (/ (+ PolyStartY BtmOxide) 2))
(define OxideThickness (+ (+ TopOxide MidOxide) BtmOxide))
(define ElectrodeRadius @radius@);;2.0 2.5 3 3.5 4.0
(define ElectrodeDiameter (* ElectrodeRadius 2))
(define SubX 25)
(define SubZ SubX)
(define Sub_SweepWidth (* SubX 2))
(define Sub_SweepHalfWidth SubX)
(define SubY 150);;150
(define DiffLength 1)

(define BackDiff 10)
(define TiptoBtmGap (+ @gap@ BackDiff));;15 20 25 30

(define ElectrodeHeight (- SubY TiptoBtmGap))
(define ElectrodeRectHeight (- ElectrodeHeight (* ElectrodeRadius 2)))

(define PsprayCon 4e16)
(define SubCon 1e12)
(define ElectrodeCon 5e19)

(define NFieldPlate 3.5)


(define CapRadius (+ ElectrodeRadius NFieldPlate))


(define NContactStartPos 1.5)

(define ElectrodeLateralDiffuse 2)
(define MaxMeshSize (/ ElectrodeLateralDiffuse 10))
(define LateralDepth (+ ElectrodeRadius ElectrodeLateralDiffuse))
(define NLateral LateralDepth)
(define PLateral LateralDepth)


;;***********************************************************
;;-----------------------------------------------------------
;;Define the silicon bulk
(define Sub (sdegeo:create-cuboid (position 0 0 0 )  (position SubX SubY SubZ) "Silicon" "SubstrateCub"))
;;(sdegeo:create-cylinder (position 0 0 0 )  (position 0 ElectrodeRectHeight 0) LateralDepth "Silicon" "NLateralCy")
;;(sdegeo:create-cylinder (position 0 ElectrodeRectHeight 0)  (position 0 (+ ElectrodeHeight LateralDepth) 0) LateralDepth "Silicon" "NTipDiff")

;;(sdegeo:create-cylinder (position SubX 0 SubZ)  (position SubX SubY SubZ) PLateral "Silicon" "PLateralCy")


;;Doping the bulk
(sdedr:define-constant-profile "SubConDoping" "BoronActiveConcentration" SubCon)
(sdedr:define-constant-profile-material "SubConDopingPlac" "SubConDoping" "Silicon")
;;***********************************************************
;;-----------------------------------------------------------
;;Define the p-spray layer, top surface
(sdedr:define-gaussian-profile "TopPsprayDoping" "BoronActiveConcentration" "PeakPos" 0.1 "PeakVal" PsprayCon "ValueAtDepth" SubCon "Depth" 0.8 "Gauss" "Factor" 0.5)
(sdedr:define-refinement-window "TopPsprayWin" "Rectangle"  (position 0 0 0)  (position SubX 0 SubZ) )
(sdedr:define-analytical-profile-placement "TopPsprayDopingPlac" "TopPsprayDoping" "TopPsprayWin" "Both" "NoReplace" "Eval")
;;***********************************************************
;;-----------------------------------------------------------
;;Define the p++ layer, btm surface
(sdedr:define-gaussian-profile "BtmPsprayDoping" "BoronActiveConcentration" "PeakPos" 0  "PeakVal" ElectrodeCon "ValueAtDepth" SubCon "Depth" BackDiff "Gauss" "Factor" 0.5)
(sdedr:define-refinement-window "BtmPsprayWin" "Rectangle"  (position 0 SubY 0)  (position SubX SubY SubZ) )
(sdedr:define-analytical-profile-placement "BtmPsprayDopingPlac" "BtmPsprayDoping" "BtmPsprayWin" "Negative" "NoReplace" "Eval")
;;-----------------------------------------------------------
;;Define the oxide
(sdegeo:create-cuboid (position 0 OxideThickness 0 )  (position SubX 0 SubZ) "SiO2" "Oxide" )
;;-----------------------------------------------------------
;;Define the n++ electrode
(define NCylinder (sdegeo:create-cylinder (position 0 0 0)  (position 0 ElectrodeRectHeight -0) ElectrodeRadius "Silicon" "NCylinderRegion"));;PolySi
;;----------------------------------------------------------Better use the create-ot-ellipsoid for the tip, create-ellipsoid would cause jag-saw for the doping of the tip
(define Ellip (sdegeo:create-ot-ellipsoid (position 0 ElectrodeRectHeight 0) (position 0 (- ElectrodeRectHeight (* ElectrodeRadius 2)) 0) 0.5 0 90 "Silicon" "EllipsoidRegion"));;PolySi
;;(define Ellip (sdegeo:create-ot-sphere (position 0 ElectrodeRectHeight 0) (gvector 0 1 0) ElectrodeRadius 90 0 "Silicon" "EllipsoidRegion"));;PolySi
(sdegeo:bool-unite (list NCylinder Ellip))
;;(extract-refpolyhedron NCylinder "BulkNElectrodeInterface")
(sdegeo:delete-region (find-body-id (position 1 1 1)));delete N++
;;(sdegeo:delete-region (find-body-id (position 0.1 (+ ElectrodeRectHeight 1) 0.1)));delete N++

;;To calculate a Arbitrary point of the cylinder/bulk interface
;; x^2 + z^2 = R  --> x = z = R/sqrt(2)
(define tmp (/ ElectrodeRadius 1.41421356237))
;;To calculate a Arbitrary point of the ellipsoid/bulk interface
;;1/x^2 + 1/y^2 + 1/z^2 = 1, when x=z=R/2 --> y, an offset of ElectrodeRectHeight will be needed.
(define ellp_tmp (+ ElectrodeRectHeight 2.82842712475))
(cond
	((= ElectrodeRadius 2.5)
		(begin
			(define ellp_tmp (+ ElectrodeRectHeight 3.53553390593))
		)
	)
	((= ElectrodeRadius 3.0)
		(begin
			(define ellp_tmp (+ ElectrodeRectHeight 4.24264068712))
		)
	)
	((= ElectrodeRadius 3.5)
		(begin
			(define ellp_tmp (+ ElectrodeRectHeight 4.94974746831))
		)
	)
	((= ElectrodeRadius 4.0)
		(begin
			(define ellp_tmp (+ ElectrodeRectHeight 5.65685424949))
		)
	)
)
;;(define ellp_tmp (+ ElectrodeRectHeight tmp));;for sphere
;;-----------------------------------------------------------The doping profile is better when the two refwindows are not combined 
(extract-refwindow  (list (car (find-face-id (position tmp 1 tmp)))) "BulkNElectrodeInterface_Cy")
(extract-refwindow  (list (car (find-face-id (position (/ ElectrodeRadius 2) ellp_tmp (/ ElectrodeRadius 2))))) "BulkNElectrodeInterface_El")

;;-----------------------------------------------------------Gaussian causes jag-saw doping profile around the Tip, err function is better
(sdedr:define-erf-profile "NElectrodeDoping_Cy" "PhosphorusActiveConcentration" "SymPos" 0  "MaxVal" ElectrodeCon "ValueAtDepth" SubCon "Length" 0.3 "Gauss"  "Factor" 0.3)
(sdedr:define-erf-profile "NElectrodeDoping_El" "PhosphorusActiveConcentration" "SymPos" 0  "MaxVal" ElectrodeCon "ValueAtDepth" SubCon "Length" 0.3 "Gauss"  "Factor" 0.3)
(sdedr:define-analytical-profile-placement "NEDopingPlac_Cy" "NElectrodeDoping_Cy" "BulkNElectrodeInterface_Cy" "Both" "NoReplace" "Eval")
(sdedr:define-analytical-profile-placement "NEDopingPlac_El" "NElectrodeDoping_El" "BulkNElectrodeInterface_El" "Both" "NoReplace" "Eval")

(define NCap (sdegeo:create-cylinder (position 0 PolyStartY 0)  (position 0 BtmOxide 0) CapRadius "Aluminum" "NCapRegion"));;PolySi
(define NCylinder1 (sdegeo:create-cylinder (position 0 2 0)  (position 0 4 0) ElectrodeRadius "Silicon" "NContactCylinder"));;PolySi

;;-----------------------------------------------------------
;;Define the p++ electrode
(define PCylinder(sdegeo:create-cylinder (position SubX 0 SubZ)  (position SubX SubY SubZ) ElectrodeRadius "Silicon" "PCylinderRegion"))
(sdegeo:delete-region (find-body-id (position (- SubX 1) 1 (- SubZ 1))));delete P++
(extract-refwindow  (list (car (find-face-id (position (- SubX tmp) 1 (- SubZ tmp))))) "BulkPElectrodeInterface")
(sdedr:define-erf-profile "PElectrodeDoping" "BoronActiveConcentration" "SymPos" 0 "MaxVal" ElectrodeCon "ValueAtDepth" SubCon "Length" 0.3 "Gauss"  "Factor" 0.3)
(sdedr:define-analytical-profile-placement "PEDopingPlac" "PElectrodeDoping" "BulkPElectrodeInterface" "Both" "NoReplace" "Eval")

(define PCap (sdegeo:create-cylinder (position SubX PolyStartY SubZ)  (position SubX BtmOxide SubZ) CapRadius "Aluminum" "PCapRegion"));;PolySi
;;***********************************************************
;;-----------------------------------------------------------Trimming
(sdegeo:body-trim 0 OxideThickness 0 SubX SubY SubZ)
;;---------------------------------------------------delete Oxide for contact
(sdegeo:create-cylinder (position (- SubX (+ NContactStartPos 1)) OxideThickness (- SubZ (+ NContactStartPos 1)))  (position (- SubX (+ NContactStartPos 1)) PolyStartY (- SubZ (+ NContactStartPos 1))) 2 "SiO2" "oxide2" )
(sdegeo:delete-region (find-body-id (position (- SubX (+ NContactStartPos 2)) (/ (+ OxideThickness PolyStartY) 2) (- SubZ (+ NContactStartPos 2)))));delete oxide2

(sdegeo:define-contact-set "P_Contact" 4  (color:rgb 0 1 0 ) "##" )
(sdegeo:set-current-contact-set "P_Contact")
(sdegeo:imprint-rectangular-wire (position  0 SubY 0)  (position SubX SubY SubZ))
(sdegeo:set-contact-faces 
	(list 
		(car (find-face-id (position (/ SubX 2) SubY (/ SubZ 2))))
	) 
	"P_Contact"
)

(sdegeo:imprint-rectangular-wire (position  (- SubX (+ NContactStartPos 0)) PolyStartY (- SubZ (+ NContactStartPos 0)))  (position (- SubX (+ NContactStartPos 2)) PolyStartY (- SubZ (+ NContactStartPos 2))))
(sdegeo:set-contact-faces 
	(list 
		(car (find-face-id (position (- SubX (+ NContactStartPos 1)) PolyStartY (- SubZ (+ NContactStartPos 1)))))
	) 
	"P_Contact"
)


(sdegeo:create-cylinder (position (+ NContactStartPos 1) OxideThickness (+ NContactStartPos 1))  (position (+ NContactStartPos 1) PolyStartY (+ NContactStartPos 1)) 2 "SiO2" "oxide3" )
(sdegeo:delete-region (find-body-id (position (+ NContactStartPos 2) (/ (+ OxideThickness PolyStartY) 2) (+ NContactStartPos 2))));delete oxide2
(sdegeo:define-contact-set "N_Contact" 4  (color:rgb 0 1 0 ) "##" )
(sdegeo:set-current-contact-set "N_Contact")
(sdegeo:imprint-rectangular-wire (position  (+ NContactStartPos 0) PolyStartY (+ NContactStartPos 0))  (position (+ NContactStartPos 2) PolyStartY (+ NContactStartPos 2)))
(sdegeo:set-contact-faces 
	(list 
		(car (find-face-id (position (+ NContactStartPos 1) PolyStartY (+ NContactStartPos 1))))
	) 
	"N_Contact"
)
(sdegeo:set-contact NCylinder1 "N_Contact" "remove")

;;***********************************************************
;;-----------------------------------------------------global mesh
(sdedr:define-refeval-window "RefWinGlobal" "Cuboid"  (position 0 0 0)  (position SubX SubY SubZ)) 	;global mesh
(sdedr:define-refinement-size "RefDefGlobal" 1 3 1 0.5 1.5 0.5);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "RefPlacGlobal" "RefDefGlobal" "RefWinGlobal")

(sdedr:define-refinement-size "CapRefSize" 1 0.1 1 0.5 0.05 0.5);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-material "CapRefPlac" "CapRefSize" "PolySi")
;;***********************************************************
;;-----------------------------------------------------Surface
(sdedr:define-refeval-window "SurfaceRefWin" "Cuboid"  (position 0 0 0)  (position SubX 0.05 SubZ)) 	;global mesh
(sdedr:define-refinement-size "SurfaceRefSize" 1 0.01 1 0.5 0.005 0.5);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "SurfaceRefPlac" "SurfaceRefSize" "SurfaceRefWin")
;;***********************************************************
;;-----------------------------------------------------Pspray
(sdedr:define-refeval-window "PsprayRefWin" "Cuboid"  (position 0 0 0)  (position SubX 1 SubZ)) 	;global mesh
(sdedr:define-refinement-size "PsprayRefSize" 1 0.1 1 0.5 0.05 0.5);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "PsprayRefPlac" "PsprayRefSize" "PsprayRefWin")

;;***********************************************************
;;-----------------------------------------------------N Surface
(sdedr:define-refeval-window "NSurfaceRefWin" "Cuboid"  (position 0 0 0)  (position NLateral 0.05 NLateral)) 	;global mesh
(sdedr:define-refinement-size "NSurfaceRefSize" MaxMeshSize 0.01 MaxMeshSize 0.05 0.005 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "NSurfaceRefPlac" "NSurfaceRefSize" "NSurfaceRefWin")

;;***********************************************************
;;-----------------------------------------------------N Pspray
(sdedr:define-refeval-window "NPsprayRefWin" "Cuboid"  (position 0 0 0)  (position NLateral 1 NLateral)) 	;global mesh
(sdedr:define-refinement-size "NPsprayRefSize" MaxMeshSize 0.1 MaxMeshSize 0.05 0.05 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "NPsprayRefPlac" "NPsprayRefSize" "NPsprayRefWin")

;;***********************************************************
;;-----------------------------------------------------N Lateral
(sdedr:define-refeval-window "NLateralRefWin" "Cuboid"  (position 0 0 0)  (position NLateral ElectrodeRectHeight NLateral)) 	;global mesh
(sdedr:define-refinement-size "NLateralRefSize" MaxMeshSize 3 MaxMeshSize 0.05 1.5 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "NLateralRefPlac" "NLateralRefSize" "NLateralRefWin")
;;(sdedr:define-refinement-region "NLateralRefPlac" "NLateralRefSize" "NLateralCy")
;;***********************************************************
;;-----------------------------------------------------N Tip
(sdedr:define-refeval-window "NTipRefWin" "Cuboid"  (position 0 ElectrodeRectHeight 0)  (position NLateral (+ ElectrodeHeight (- LateralDepth 0.2)) NLateral)) 	;global mesh
(sdedr:define-refinement-size "NTipRefSize" MaxMeshSize MaxMeshSize MaxMeshSize 0.05 0.05 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "NTipRefPlac" "NTipRefSize" "NTipRefWin")
;;(sdedr:define-refinement-region "NElectrodeLaterall_Plac" "NTipRefSize" "NTipDiff")


;;***********************************************************
;;-----------------------------------------------------P++ Surface
(sdedr:define-refeval-window "PSurfaceRefWin" "Cuboid"  (position (- SubX PLateral) 0 (- SubZ PLateral))  (position SubX 0.05 SubZ)) 	;global mesh
(sdedr:define-refinement-size "PSurfaceRefSize" MaxMeshSize 0.01 MaxMeshSize 0.05 0.005 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "PSurfaceRefPlac" "PSurfaceRefSize" "PSurfaceRefWin")

;;***********************************************************
;;-----------------------------------------------------P++ Pspray
(sdedr:define-refeval-window "PPsprayRefWin" "Cuboid"  (position (- SubX PLateral) 0 (- SubZ PLateral))  (position SubX 1 SubZ)) 	;global mesh
(sdedr:define-refinement-size "PPsprayRefSize" MaxMeshSize 0.1 MaxMeshSize 0.05 0.05 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "PPsprayRefPlac" "PPsprayRefSize" "PPsprayRefWin")

;;***********************************************************
;;-----------------------------------------------------P Lateral
(sdedr:define-refeval-window "PLateralRefWin" "Cuboid"  (position (- SubX PLateral) 0 (- SubZ PLateral))  (position SubX SubY SubZ)) 	;global mesh
(sdedr:define-refinement-size "PLateralRefSize" MaxMeshSize 3 MaxMeshSize 0.05 1.5 0.05);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "PLateralRefPlac" "PLateralRefSize" "PLateralRefWin")
;;(sdedr:define-refinement-region "PLateralRefPlac" "PLateralRefSize" "PLateralCy")
;;***********************************************************
;;-----------------------------------------------------P Btm junction
(sdedr:define-refeval-window "PBtmRefWin" "Cuboid"  (position (- SubX PLateral) (- SubY BackDiff) (- SubZ PLateral))  (position SubX SubY SubZ)) 	;global mesh
(sdedr:define-refinement-size "PBtmRefSize" MaxMeshSize 1 MaxMeshSize 0.05 0.5 0.05)
(sdedr:define-refinement-placement "PBtmRefPlac" "PBtmRefSize" "PBtmRefWin")

;;***********************************************************
;;-----------------------------------------------------P Back Diff
(sdedr:define-refeval-window "PBackRefWin" "Cuboid"  (position 0 (- SubY BackDiff) 0)  (position SubX SubY SubZ)) 	;global mesh
(sdedr:define-refinement-size "PBackRefSize" 1 1 1 0.5 0.25 0.5);1 3 1 0.5 1.5 0.5
(sdedr:define-refinement-placement "PBackRefPlac" "PBackRefSize" "PBackRefWin")


; saves the model file and the mesh file 
(sde:save-model "p@node@")
(sdesnmesh:set-iocontrols "numThreads" 16)
(sde:build-mesh "snmesh" "-a -c boxmethod" "n@node@")
