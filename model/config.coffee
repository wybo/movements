u = ABM.util # ABM.util alias
log = (object) -> console.log object

ABM.TYPES = {normal: "0", enclave: "1", micro: "2"}
ABM.MEDIA = {email: "0", website: "1", forum: "2"}
# turn back to numbers once dat.gui fixed

class Config
#  medium: ABM.MEDIA.email
  medium: ABM.MEDIA.forum
#  medium: ABM.MEDIA.website
  type: ABM.TYPES.normal
  citizenDensity: 0.7
  copDensity: 0.02
