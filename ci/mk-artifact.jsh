var osFullName = System.getProperty("os.name").toLowerCase().replace(" ", "");
var os = switch(osFullName) {
  case String str when str.contains("windows") -> "win32";
  case String str when str.contains("macos") -> "darwin";
  default -> osFullName;
}

System.out.println("OS full name is '"+osFullName+"'");
System.out.println("OS internal name: '"+os+"'");

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

System.out.println("Arch full name: '"+archFullName+"'");
System.out.println("Arch internal name: '"+arch+"'");

var extension = switch(os) {
  case "win32" -> "dll";
  case "darwin" -> "dylib";
  default -> "so";
}

System.out.println("Looking for [lib]usbjava."+extension);

var dir = new File("publish/"+os+"-"+arch);
dir.mkdirs();

var artifactFolder = Files.exists(Paths.get("build/src/Release/")) ? Paths.get("build/src/Release/") : Paths.get("build/src/");
var lib = Files.walk(artifactFolder).filter(path -> path.toString().endsWith(extension)).toList().getFirst();

Files.move(lib, dir.toPath().resolve(lib.getFileName()), StandardCopyOption.ATOMIC_MOVE);
/exit
