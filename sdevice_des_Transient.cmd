** variables definitions **

#set EsA          0.56
#set EsD          0.60
#set EnergyMidA   0.84
#set EnergyMidD   0.30

#set Qoxpre       8.0e10
#set Nitaccpre    7.0e09
#set Nitdonpre    9.0e09
#set Qox Qoxpre
#set Ditacc -1
#set Ditdon -1

#if "@dose@" == 0
    #set Ditacc  [format %.2e @<Nitaccpre/0.3>@]
    #set Ditdon  [format %.2e @<Nitdonpre/0.3>@]
    #set Qox     [format %.2e @Qoxpre@]
#else
    #set Ditacc  [format %.2e [expr @<(Nitaccpre + 1.58e+12 + 3.76e+11*log(dose))/EsA>@] ]
    #set Ditdon  [format %.2e [expr @<(Nitdonpre + 6.28e+11 + 1.98e+11*log(dose))/0.3>@] ]
    #set Qox     [format %.2e [expr @<(Qoxpre + 5.86e+11 + 1.24e+11*log(dose))>@]]
#endif


Electrode {
	{ Name="N_Contact" Voltage=0.0 }
	{ Name="P_Contact" Voltage=0.0 }
}
 
File {
	* input files:
        grid= "@tdr@"
	* output files:
        output= "@node@_output"
        current="@plot@"
        plot=   "@tdrdat@"
        param = "@parameter@"
}
	
Plot {
	eDensity hDensity
	TotalCurrent/Vector 
	#eCurrent/Vector hCurrent/Vector
	ElectricField/Vector 
	#Potential
	#SpaceCharge
	Doping 
	#SurfaceRecombination
	eAvalanche hAvalanche
	ImpactIonization
	AvalancheGeneration
}

Math {
  	Extrapolate			
  	Derivatives 
	AvalDerivatives		
  	RelErrControl
	ParallelToInterfaceInBoundaryLayer (-ExternalBoundary)
	eMobilityAveraging= ElementEdge       
	hMobilityAveraging= ElementEdge       
      	ElementVolumeAvalanche
  	ErrRef(electron)=1.0e10
	ErrRef(hole)=1.0e10
  	Digits=5		
  	Notdamped=100
  	Iterations=20
  	Number_of_Threads = 8
	Method = Blocked 	
	SubMethod = ParDiSo
	
      	RefDens_eGradQuasiFermi_ElectricField= 1e12
     	RefDens_hGradQuasiFermi_ElectricField= 1e12
      	AvalFlatElementExclusion=2
      	AvalDensGradQF
   	Transient= BE
	#if @dose@ == 0 && @fluence@ == 0
      		BreakCriteria {Current (Contact = "N_Contact" absval = 2e-13)}
	#else
      		BreakCriteria {Current (Contact = "N_Contact" absval = 1e-10)}
	#endif
}

Solve {

	Coupled(Iterations=100 LineSearchDamping= 1e-4){ Poisson }
	Coupled (Iterations=100 LineSearchDamping= 1e-4){Poisson Electron Hole}

	Transient(
		InitialTime=0 FinalTime=1
		InitialStep=1e-12 MaxStep=5e-3 MinStep=1e-12
		Increment=1.5
		Goal{ Name="P_Contact" Voltage=-200} 
		Plot{Range=(0.5 1) Intervals=10}
	) { Coupled{ Poisson Electron Hole }}
}

Physics {
	Fermi 
	Mobility(HighFieldSat DopingDep CarrierCarrierScattering)
	EffectiveIntrinsicDensity(OldSlotboom)
	Recombination( SRH(DopingDependence) Auger Avalanche(ElectricField))
	#if @dose@ == 0 && @fluence@ == 0
		Temperature = 290
	#else
		Temperature = 248
	#endif
	}

Physics (MaterialInterface="Silicon/Oxide"){
	Traps(
		(FixedCharge Conc=@Qox@ )
		(Acceptor  Conc=@<Ditacc>@  Uniform EnergyMid=@EnergyMidA@  EnergySig=@EsA@  fromValBand  eXsection=1.00e-16  hXsection=1.00e-15  Add2TotalDoping)
		(Donor     Conc=@<Ditdon>@  Uniform EnergyMid=@EnergyMidD@  EnergySig=@EsD@  fromValBand  eXsection=1.00e-15  hXsection=1.00e-16  Add2TotalDoping)
	)
}

#if "@fluence@" > "0"
Physics (material="Silicon") {
	# Putting traps in silicon region
 	*Traps (    
	*	#if "@fluence@" <= "7.0e15"
        *      		(Acceptor Level fromCondBand  Conc=@<fluence*0.9>@  EnergyMid=0.46  eXsection=7.0E-15  hXsection=7.0E-14)
        *	#elif "@fluence@" > "7.0e15" && "@fluence@" <= "1.5e16"
        *      		(Acceptor Level fromCondBand  Conc=@<fluence*0.9>@  EnergyMid=0.46  eXsection=3.0E-15  hXsection=3.0E-14)
        *	#elif "@fluence@" > "1.5e16" && "@fluence@" <= "2.2e16"
        *      		(Acceptor Level fromCondBand  Conc=@<fluence*0.9>@  EnergyMid=0.46  eXsection=1.5E-15  hXsection=1.5E-14)
        *	#endif	
        *	(Donor Level fromValBand  Conc=@<fluence*0.9>@  EnergyMid=0.36  eXsection=3.23E-13  hXsection=3.23E-14)
        *)
	*Traps (
        *	(Donor Level    fromCondBand  Conc=@<fluence*0.006>@  EnergyMid=0.23  eXsection=2.3E-14  hXsection=2.3E-15)
	*	(Acceptor Level fromCondBand  Conc=@<fluence*1.613>@  EnergyMid=0.42  eXsection=1.0E-15  hXsection=1.0E-14)
        *      	(Acceptor Level fromCondBand  Conc=@<fluence*0.900>@  EnergyMid=0.46  eXsection=7.0E-14  hXsection=7.0E-13)
 	*)
     	Traps (
		(Acceptor Level fromCondBand  Conc=@<fluence*0.75>@  EnergyMid=0.525  eXsection=5E-15 hXsection=1E-14)
		(Acceptor Level fromValBand Conc=@<fluence*36>@ EnergyMid=0.9  eXsection=1E-16 hXsection=1E-16 )
		(Donor Level fromValBand  Conc=@<fluence*4>@  EnergyMid=0.48  eXsection=2E-14 hXsection=1E-14 )
        )
 
}
#endif
