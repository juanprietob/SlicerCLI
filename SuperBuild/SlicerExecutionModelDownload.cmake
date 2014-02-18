set( ListModules
     MedianImageFilter
     N4ITKBiasFieldCorrection
     ResampleDTIVolume
     ResampleScalarVectorDWIVolume 
     AffineRegistration
     RigidRegistration
     ThresholdScalarVolume
     AddScalarVolumes
 	BSplineDeformableRegistration
BSplineToDeformationField
CastScalarVolume
CheckerBoardFilter
ConnectedComponent
DWIJointRicianLMMSEFilter
DWIRicianLMMSEFilter
#DWIToDTIEstimation
#DWIUnbiasedNonLocalMeansFilter
#DiffusionTensorScalarMeasurements
#DiffusionWeightedVolumeMasking
GaussianBlurImageFilter
GradientAnisotropicDiffusion
 	GrayscaleFillHoleImageFilter
HistogramMatching
ImageLabelCombine
 	LabelMapSmoothing
LinearRegistration
MaskScalarVolume
#MultiplyScalarVolumes->vtkITK
OrientScalarVolume
OtsuThresholdImageFilter
OtsuThresholdSegmentation
RobustStatisticsSegmenter
SimpleRegionGrowingSegmentation
SubtractScalarVolumes
ThresholdScalarVolume
VotingBinaryHoleFillingImageFilter
   )
if( ${Slicer_Revision} GREATER 0 )
  set( get_revision "-r ${Slicer_Revision}" )
endif()
foreach( var ${ListModules} )
  execute_process( COMMAND ${Subversion_SVN_EXECUTABLE} export https://github.com/Slicer/Slicer/trunk/Modules/CLI/${var} ${DOWNLOAD_DIR}/Modules/CLI/${var} --force ${get_revision} )
  file(READ ${DOWNLOAD_DIR}/Modules/CLI/${var}/CMakeLists.txt CMakeLists)
  string(REPLACE "LOGO_HEADER" "EXECUTABLE_ONLY LOGO_HEADER" CMakeListsModified ${CMakeLists} )
  file(WRITE ${DOWNLOAD_DIR}/Modules/CLI/${var}/CMakeLists.txt ${CMakeListsModified} )
endforeach()
execute_process( COMMAND ${Subversion_SVN_EXECUTABLE} export https://github.com/Slicer/Slicer/trunk/Resources ${DOWNLOAD_DIR}/Resources --force ${get_revision} )
execute_process( COMMAND ${Subversion_SVN_EXECUTABLE} export https://github.com/Slicer/Slicer/trunk/Libs/ITKFactoryRegistration ${DOWNLOAD_DIR}/Libs/ITKFactoryRegistration --force ${get_revision} )
execute_process( COMMAND ${Subversion_SVN_EXECUTABLE} export https://github.com/Slicer/Slicer/trunk/Base/CLI ${DOWNLOAD_DIR}/Base/CLI --force ${get_revision} )
file(READ ${DOWNLOAD_DIR}/Libs/ITKFactoryRegistration/CMakeLists.txt FactoryCMakeLists)
string(REPLACE "SHARED" "STATIC" FactoryCMakeListsModified ${FactoryCMakeLists} )
file(WRITE ${DOWNLOAD_DIR}/Libs/ITKFactoryRegistration/CMakeLists.txt ${FactoryCMakeListsModified})
