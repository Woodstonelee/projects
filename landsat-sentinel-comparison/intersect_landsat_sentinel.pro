pro intersect_landsat_sentinel
compile_opt idl2

; Start the application
e = ENVI()

; Open the MODIS LST raster
File1 =  '/neponset/nbdata06/albedo/zhan.li/sentinel-2/l2a/S2A_USER_PRD_MSIL2A_PDMC_20160107T014224_R111_V20160106T154314_20160106T154314.SAFE/GRANULE/S2A_USER_MSI_L2A_TL_MTI__20160106T203715_A002825_T19TCH_N02.01/IMG_DATA/R20m/S2A_USER_MSI_L2A_TL_MTI__20160106T203715_A002825_T19TCH_TrueColor_RegLandsat_20m.jp2.bin'
MODISRaster = e.OpenRaster(File1)
MODISCoordSysString = MODISRaster.SPATIALREF.COORD_SYS_STR
MODISCoordSys = ENVICoordSys(COORD_SYS_STR=MODISCoordSysString)

; Open the Suomi NPP VIIRS LST raster
File2 = '/neponset/nbdata06/albedo/zhan.li/landsat-8/LC80120302015304LGN00/LC80120302015304LGN00_sr_true_color.bin'
VIIRSRaster = e.OpenRaster(File2)
VIIRSCoordSysString = VIIRSRaster.SPATIALREF.COORD_SYS_STR
VIIRSCoordSys = ENVICoordSys(COORD_SYS_STR=VIIRSCoordSysString)

; Create a grid definition with the same coordinate
; system and dimensions as the input MODIS raster
MODISGrid = ENVIGridDefinition(MODISCoordSys, $
  PIXEL_SIZE=MODISRaster.SPATIALREF.PIXEL_SIZE, $
  NROWS=MODISRaster.NROWS, $
  NCOLUMNS=MODISRaster.NCOLUMNS, $
  TIE_POINT_MAP=MODISRaster.SPATIALREF.TIE_POINT_MAP, $
  TIE_POINT_PIXEL=MODISRaster.SPATIALREF.TIE_POINT_PIXEL)

; Create a grid definition with the same coordinate
; system and dimensions as the input VIIRS raster
VIIRSGrid = ENVIGridDefinition(VIIRSCoordSys, $
  PIXEL_SIZE=VIIRSRaster.SPATIALREF.PIXEL_SIZE, $
  NROWS=VIIRSRaster.NROWS, $
  NCOLUMNS=VIIRSRaster.NCOLUMNS, $
  TIE_POINT_MAP=VIIRSRaster.SPATIALREF.TIE_POINT_MAP, $
  TIE_POINT_PIXEL=VIIRSRaster.SPATIALREF.TIE_POINT_PIXEL)

; Get the intersection of the two rasters
SpatialExtent = MODISGrid.Intersection(VIIRSGrid)
IntersectGrid = ENVIGridDefinition(MODISCoordSys, $
  EXTENT=SpatialExtent, $
  PIXEL_SIZE=MODISRaster.SPATIALREF.PIXEL_SIZE)

ReprojectedMODIS = ENVISpatialGridRaster(MODISRaster, $
  GRID_DEFINITION=IntersectGrid)

ReprojectedVIIRS = ENVISpatialGridRaster(VIIRSRaster, $
  GRID_DEFINITION=IntersectGrid)

; Display the reprojected rasters
View = e.GetView()
Layer1 = View.CreateLayer(ReprojectedMODIS)
Layer2 = View.CreateLayer(ReprojectedVIIRS)
View.Animate, 2.0, /FLICKER
end