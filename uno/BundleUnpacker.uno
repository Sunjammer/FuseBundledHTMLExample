using Uno;
using Uno.IO;
using Uno.UX;
using Uno.Text;
using Uno.Threading;
using Fuse.Scripting;
using Uno.Compiler.ExportTargetInterop;

namespace BundleUnpacker
{
	[UXGlobalModule]
	public class BundleUnpacker : NativeModule
	{
		static readonly BundleUnpacker _instance;
		public BundleUnpacker()
		{
			if(_instance != null) return;
			Resource.SetGlobalKey(_instance = this, "BundleUnpacker");
			AddMember(new NativePromise<string, Fuse.Scripting.Object>("unpack", Unpack, null));
		}
		
		static bool IsPathEqual(string src, string path)
		{
			return src == path;
		}
		
		static BundleFile GetFile(string path)
		{
			foreach (var f in Bundle.AllFiles)
			{
				if (IsPathEqual(f.SourcePath, path)) return f;
			}
			return null;
		}
		
		static Future<string> Unpack(object[] args)
		{
			return UnpackFile(args);
		}
		
		static Future<string> UnpackFile(object[] args)
		{
			var p = new Promise<string>();
			var searchPath = args.ValueOrDefault<string>(0, "");
			var overwrite = args.ValueOrDefault<bool>(1,false);
			if(searchPath!="")
			{
				BundleFile file = GetFile(searchPath);
				if(file != null)
				{
					var path = GetTempDir() + "/" + searchPath;
					if(overwrite || !File.Exists(path))
					{
						try
						{
							Directory.CreateDirectory(Path.GetDirectoryName(path));
							File.WriteAllBytes(path, file.ReadAllBytes());
						}
						catch(Exception e)
						{
							p.Reject(e);
							return p;
						}
					}
					p.Resolve("file://"+path);
				}
				else
				{
					p.Reject(new Exception("Invalid bundle file path '"+searchPath+"'"));
				}
			}
				
			return p;
		}
		
		[Foreign(Language.ObjC)]
		static extern(iOS) string GetTempDir()
		@{
			return NSTemporaryDirectory();
		@}
		
		[Foreign(Language.Java)]
		static extern(Android) string GetTempDir()
		@{
			return com.fuse.Activity.getRootActivity().getExternalCacheDir().getAbsolutePath();
		@}
		
		static extern(!Mobile) string GetTempDir()
		{
			var dir = Uno.IO.Directory.GetUserDirectory(Uno.IO.UserDirectory.Data) + "/Fuse_ExtractedBundles"; //Not exactly a killer approach, this
				if (!Directory.Exists(dir))
					Directory.CreateDirectory(dir);
			return dir;
		}
	}
}
