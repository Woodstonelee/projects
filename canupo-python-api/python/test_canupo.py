import canupo

mscfile = canupo.MSCFile("/media/sf_Windows-Workspace/data/dwel-processing/hfhd20140919/dual-wl-points/HFHD_20140919_C_dual_cube_bsfix_pxc_update_atp2_ptcl_points_az10.msc")

# scales = canupo.FloatVec()
# scales[:] = []
# ptnparams = canupo.RefInt(0)

# print canupo.read_msc_header(mscfile, scales, ptnparams)
npts, scales, nparams = canupo.read_msc_header(mscfile)
import pdb; pdb.set_trace()
data = canupo.FloatVec()
# canupo.read_msc_data(mscfile, len(scales), npts, data, nparams, True)
canupo.read_msc_data(mscfile, len(scales), npts, data, nparams)
