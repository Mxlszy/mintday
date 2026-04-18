package com.mintday.mintday

import android.content.pm.ApplicationInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterShellArgs

class MainActivity : FlutterActivity() {
    override fun getFlutterShellArgs(): FlutterShellArgs {
        val args = super.getFlutterShellArgs()
        val isDebuggable =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (isDebuggable) {
            args.add(FlutterShellArgs.ARG_ENABLE_SOFTWARE_RENDERING)
            args.add(FlutterShellArgs.ARG_DISABLE_IMPELLER)
        }
        return args
    }
}
