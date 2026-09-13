var osFullName = System.getProperty("os.name").toLowerCase();
var os = switch(osFullName) {
  case String str when str.contains("windows") -> "win32";
  case String str when str.contains("macos") -> "darwin";
  default -> osFullName;
}

var archFullName = System.getProperty("os.arch").toLowerCase();
var arch = switch(archFullName) {
  case String str when str.equals("i386") -> "x86";
  case String str when str.equals("amd64") || 
                       str.equals("x86_64") -> "x86-64";
  case String str when str.equals("arm64") -> "aarch64";
  case String str when str.equals("armhf") || 
                       str.equals("astr32") || 
                       str.equals("armv7l") -> "arm";
  default -> archFullName;
}
new File("publish/"+os+"-"+arch).mkdirs();
/exit
