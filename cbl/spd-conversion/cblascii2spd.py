#!/usr/bin/env python
"""
Create an SPD file from a CBL ascii file
John Armston, j.armston@uq.edu.au
"""

import optparse
import sys
import numpy as np
import spdpy
from scipy import constants


def file_len(fname):
    """
    Number of lines in a text file
    """
    with open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1
    

def spherical2cartesian(phi,theta,r):
    """
    Converts spherical to cartesian coordinates
    """
    x = r * np.sin(phi) * np.sin(theta)
    y = r * np.cos(phi) * np.sin(theta)
    z = r * np.cos(theta)
    return (x,y,z)


def create_point(tof,theta,phi,intensity,n):
    """
    Create an SPD point
    """
    #r = ((tof / 1e9) * constants.c) / 2.0
    r = tof / 1000.0
    x,y,z = spherical2cartesian(phi,theta,r)
    point = spdpy.createSPDPointPy()
    point.returnID = n-1
    point.x = x
    point.y = y
    point.z = z
    point.range = r
    point.amplitudeReturn = intensity
    return point
  

def main(cmdargs):
    """
    Read a CBL ascii file and write to a scan project SPD file
    Columns: Intensity, Azimuth, Zenith, Time of Flight and Return Number
    """    
    # Get file information
    zenith_resolution = 0.5
    azimuth_resolution = 0.25
    num_scanlines = 721
    num_scanlinepulses = 541    
    numrecords = file_len(cmdargs.infile)
    
    # Open output SPD file
    outfile = cmdargs.infile.replace(".txt",".spd")
    spdoutfile = spdpy.createSPDFile(outfile)
    spdoutfile.setNumBinsX(num_scanlinepulses)
    spdoutfile.setNumBinsY(num_scanlines)
    spdoutfile.setBinSize(1)
    spdwriter = spdpy.SPDPySeqWriter()
    spdwriter.open(spdoutfile, outfile)
    
    # Define the data present
    spdoutfile.setReceiveWaveformDefined(0)
    spdoutfile.setTransWaveformDefined(0)
    spdoutfile.setDecomposedPtDefined(0)
    spdoutfile.setDiscretePtDefined(1)
    spdoutfile.setOriginDefined(1)
    spdoutfile.setHeightDefined(0)
    spdoutfile.setRgbDefined(0)
    
    # Set header attributes
    spdoutfile.setSensorHeight(1.2)
    spdoutfile.setBeamDivergence(15.0)
    spdoutfile.setPulseIdxMethod(5)
    spdoutfile.setZenithMin(0)
    spdoutfile.setZenithMax(135) 
    spdoutfile.setAzimuthMin(0)
    spdoutfile.setAzimuthMax(360)
        
    # now read through the file
    pulsecount = 0
    zenithcoltemp = -1.0
    scanlineidxtemp = 1
    scanlinecount = 1
    scanline = list()
    f = open(cmdargs.infile, 'r')
    for i,line in enumerate(f):
        lparts = line.strip('\r\n').split()
        if len(lparts) > 0:
            
            # pulse - need to assume data is time sequential
            returnnum = int(float(lparts[4]))
            
            # Pulses with no returns
            if returnnum == 0:
                if i > 0:
                    scanline.append([pulse])                
                pulsecount += 1
                pulse = spdpy.createSPDPulsePy()            
                pulse.pulseID = pulsecount
                zenithcoltemp += 1              
                pulse.numberOfReturns = returnnum
                
                # If it's a new scan line, write out previous one and set up new one 
                if zenithcoltemp > 540:
                    spdwriter.writeDataRow(scanline, scanlinecount-1)
                    scanline = list()
                    scanlinecount += 1
                    scanlineidxtemp = 1
                    pulse.zenith = 135
                    zenithcoltemp = 0
                else:
                    scanlineidxtemp += 1
                    pulse.zenith = abs(float(zenithcoltemp)*zenith_resolution - 135)            
                
                # Calculate azimuth angle
                if zenithcoltemp > 270:
                    pulse.azimuth = float(lparts[1]) * azimuth_resolution + 180
                else:
                    pulse.azimuth = float(lparts[1]) * azimuth_resolution                
                
                pulse.xIdx = scanlineidxtemp
                pulse.yIdx = scanlinecount
                pulse.scanline = scanlinecount
                pulse.scanlineIdx = scanlineidxtemp
            
            # First return
            elif returnnum == 1:
                if i > 0:
                    scanline.append([pulse])
                
                # Initialise new pulse
                pulsecount += 1
                pulse = spdpy.createSPDPulsePy()            
                pulse.pulseID = pulsecount
                pulse.numberOfReturns = returnnum
                
                # If it's a new scan line, write out previous one and set up new one
                if float(lparts[2]) < zenithcoltemp: 
                    spdwriter.writeDataRow(scanline, scanlinecount-1)
                    scanline = list()
                    scanlinecount += 1
                    scanlineidxtemp = 1
                else:
                    scanlineidxtemp += 1
                
                # Calculate zenith angle
                pulse.zenith = abs(float(lparts[2]) * zenith_resolution - 135)
                
                # Calculate azimuth angle
                if zenithcoltemp > 270:
                    pulse.azimuth = float(lparts[1]) * azimuth_resolution + 180
                else: 
                    pulse.azimuth = float(lparts[1]) * azimuth_resolution
                
                pulse.xIdx = scanlineidxtemp
                pulse.yIdx = scanlinecount
                pulse.scanline = scanlinecount
                pulse.scanlineIdx = scanlineidxtemp             
                zenithcoltemp = float(lparts[2])
            
            # Second return
            elif returnnum == 2:
                pulse.numberOfReturns = returnnum
            
            # Create a return if one exists
            if returnnum > 0:
                tof = float(lparts[0])
                intensity = float(lparts[3])               
                point = create_point(tof,np.radians(pulse.zenith),np.radians(pulse.azimuth),intensity,returnnum)
                pulse.pts.append(point)
    
        # Let's monitor progress
        sys.stdout.write("Writing sequential SPD file %s (%i%%)\r" % (outfile, scanlinecount / float(num_scanlines) * 100))        
    
    
    # Write last scan line
    scanline.append([pulse])
    spdwriter.writeDataRow(scanline, scanlinecount-1)
    spdoutfile.setNumPulses(pulsecount)

    # Close the output file
    f.close()
    spdwriter.close(spdoutfile)



# Command arguments
class CmdArgs:
  def __init__(self):
    p = optparse.OptionParser()
    p.add_option("-i","--infile", dest="infile", default="TLSIIGCampaign_CBL_Reprocessed/07302013KarawathaSite005/SICK_UMB_2013-07-30_122733_full.txt", help="Input CBL ASCII file")
    (options, args) = p.parse_args()
    self.__dict__.update(options.__dict__)
    
    if (self.infile is None):
        p.print_help()
        print "Input filename must be set."
        sys.exit()


# Run the script
if __name__ == "__main__":
    cmdargs = CmdArgs()
    main(cmdargs)
