echo '
{
	"fx": 968.7,
	"fy": 966.0,
	"cx": 646.5,
	"cy": 365.5,
	"k1": -0.4,
	"k2": 0.15,
	"k3": 0.0,
	"p1": 0.000644,
	"p2": 0.0012,
	"H": 720,
	"W": 1280,
	"image_topic": "/camera/color/image_raw",
	"pose_topic": "/orb_slam3/camera_pose"
}
' > /home/rover/ASCC_CONTAINER/nerf_bridge/nsros_config_sample.json

echo '
[submodule "nerfstudio"]
	path = nerfstudio
	url = git@github.com:nerfstudio-project/nerfstudio.git
' > /home/rover/ASCC_CONTAINER/nerf_bridge/.gitmodules
