# enable experimental vulkan video
[[ "${ANV_DEBUG}" == *video-decode* ]] || ANV_DEBUG="${ANV_DEBUG+${ANV_DEBUG},}video-decode"
[[ "${ANV_DEBUG}" == *video-encode* ]] || ANV_DEBUG="${ANV_DEBUG+${ANV_DEBUG},}video-encode"
export ANV_DEBUG
