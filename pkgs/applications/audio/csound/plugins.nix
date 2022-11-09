{ stdenv, lib, cmake, csound, fetchFromGitHub, Accelerate, eigen, faust, fltk, python3, zlib }:

stdenv.mkDerivation rec {
  pname = "csound-plugins";
  version = "b9512b21ef86b8b824ac76130ed2421481a398eb";

  src = fetchFromGitHub {
    owner = "csound";
    repo = "plugins";
    rev = version;
    sha256 = "sha256-jvt8CKbiwtF4sVzN+KxApZofCchqDrtNw/DoG5VM5L4=";
  };

  HOME = "${placeholder "out"}";

  cmakeFlags = [
    "-DBUILD_CHUA_OPCODES=ON"
    "-DCSOUND_INCLUDE_DIR=${csound}/include"
    "-DCSOUND_INCLUDE_DIRS=${csound}/include"
    "-DUSE_FLTK=ON"
    "-DBUILD_FAUST_OPCODES=ON"
  ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    Accelerate
    eigen
    faust
    fltk
    python3
    zlib
  ];

  meta = with lib; {
    description = "Sound design, audio synthesis, and signal processing system, providing facilities for music composition and performance on all major operating systems and platforms";
    homepage = "https://csound.com/";
    license = licenses.lgpl21Plus;
    maintainers = [maintainers.hlolli];
    platforms = platforms.unix;
  };
}
