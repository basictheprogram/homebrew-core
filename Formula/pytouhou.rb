class Pytouhou < Formula
  desc "Libre implementation of Touhou 6 engine"
  homepage "https://pytouhou.linkmauve.fr/"
  url "https://hg.linkmauve.fr/touhou", :revision => "5270c34b4c00", :using => :hg
  version "634"
  revision 6
  head "https://hg.linkmauve.fr/touhou", :using => :hg

  bottle do
    cellar :any
    sha256 "9d69c15cda311bcf63cb37ff939d4ea4f1b7d675de4450ea00f35d2ec628305c" => :catalina
    sha256 "f2bf5020d5fbf9e83847d416e8909bb583cbea9ce406453d2471dbbb6945b202" => :mojave
    sha256 "f5e3c88bea9e1a533f0a96b401df4c2df90195d684ab8ecc2fc9471b9a09a4cd" => :high_sierra
    sha256 "48d508217894d69689ba1d9c1ee65fab622f0895a7358e928dba38516c004de0" => :sierra
    sha256 "edb451dc773f69a0550c687b90326d9baecb5d2bd1898b32cc550662b90c6eeb" => :el_capitan
  end

  depends_on "pkg-config" => :build
  depends_on "glfw"
  depends_on "gtk+3"
  depends_on "libepoxy"
  depends_on "py3cairo"
  depends_on "pygobject3"
  depends_on "python@3.8"
  depends_on "sdl2"
  depends_on "sdl2_image"
  depends_on "sdl2_mixer"
  depends_on "sdl2_ttf"

  resource "Cython" do
    url "https://files.pythonhosted.org/packages/a5/1f/c7c5450c60a90ce058b47ecf60bb5be2bfe46f952ed1d3b95d1d677588be/Cython-0.29.13.tar.gz"
    sha256 "c29d069a4a30f472482343c866f7486731ad638ef9af92bfe5fca9c7323d638e"
  end

  # Fix for parallel cythonize
  # It just put setup call in `if __name__ == '__main__'` block
  patch :p0, :DATA

  def install
    pyver = Language::Python.major_minor_version "python3"
    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python#{pyver}/site-packages"
    resource("Cython").stage do
      system "python3", *Language::Python.setup_install_args(libexec/"vendor")
    end

    # hg can't determine revision number (no .hg on the stage)
    inreplace "setup.py", /(version)=.+,$/, "\\1='#{version}',"
    ENV.prepend_create_path "PYTHONPATH", libexec/"lib/python#{pyver}/site-packages"
    system "python3", *Language::Python.setup_install_args(libexec)

    # Set default game path to pkgshare
    inreplace "#{libexec}/bin/pytouhou", /('path'): '\.'/, "\\1: '#{pkgshare}/game'"

    bin.install Dir[libexec/"bin/*"]
    bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])
  end

  def caveats; <<~EOS
    The default path for the game data is:
      #{pkgshare}/game
  EOS
  end

  test do
    ENV["LC_ALL"] = "en_US.UTF-8"
    system "#{bin}/pytouhou", "--help"
  end
end

__END__
--- setup.py	2019-10-21 08:55:06.000000000 +0100
+++ setup.py	2019-10-21 08:56:15.000000000 +0100
@@ -172,29 +172,29 @@
 if not os.path.exists(temp_data_dir):
     os.symlink(os.path.join(current_dir, 'data'), temp_data_dir)

+if __name__ == '__main__':
+    setup(name='PyTouhou',
+        version=check_output(['hg', 'heads', '.', '-T', '{rev}']).decode(),
+        author='Thibaut Girka',
+        author_email='thib@sitedethib.com',
+        url='http://pytouhou.linkmauve.fr/',
+        license='GPLv3',
+        py_modules=py_modules,
+        ext_modules=cythonize(ext_modules, nthreads=nthreads, annotate=debug,
+                                language_level=3,
+                                compiler_directives={'infer_types': True,
+                                                    'infer_types.verbose': debug,
+                                                    'profile': debug},
+                                compile_time_env={'MAX_TEXTURES': 128,
+                                                'MAX_ELEMENTS': 640 * 4 * 3,
+                                                'MAX_SOUNDS': 26,
+                                                'USE_OPENGL': use_opengl}),
+        scripts=['scripts/pytouhou'] + (['scripts/anmviewer'] if anmviewer else []),
+        packages=['pytouhou'],
+        package_data={'pytouhou': ['data/menu.glade']},
+        **extra)

-setup(name='PyTouhou',
-      version=check_output(['hg', 'heads', '.', '-T', '{rev}']).decode(),
-      author='Thibaut Girka',
-      author_email='thib@sitedethib.com',
-      url='http://pytouhou.linkmauve.fr/',
-      license='GPLv3',
-      py_modules=py_modules,
-      ext_modules=cythonize(ext_modules, nthreads=nthreads, annotate=debug,
-                            language_level=3,
-                            compiler_directives={'infer_types': True,
-                                                 'infer_types.verbose': debug,
-                                                 'profile': debug},
-                            compile_time_env={'MAX_TEXTURES': 128,
-                                              'MAX_ELEMENTS': 640 * 4 * 3,
-                                              'MAX_SOUNDS': 26,
-                                              'USE_OPENGL': use_opengl}),
-      scripts=['scripts/pytouhou'] + (['scripts/anmviewer'] if anmviewer else []),
-      packages=['pytouhou'],
-      package_data={'pytouhou': ['data/menu.glade']},
-      **extra)

-
-# Remove the link afterwards
-if os.path.exists(temp_data_dir):
-    os.unlink(temp_data_dir)
+    # Remove the link afterwards
+    if os.path.exists(temp_data_dir):
+        os.unlink(temp_data_dir)
