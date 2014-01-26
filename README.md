CCLoader
========

Available to download from Cydia: http://cydia.saurik.com/package/de.j-gessner.ccloader

###General
CCLoader loads custom sections into the iOS 7 Control Center. Templates for creating a CCLoader plugin are available for theos and for iOSOpenDev:
<p>
CCLoader Plugin template for theos: https://github.com/JonasGessner/Theos-NIC-Templates<br>
CCLoader Plugin template for iOSOpenDev: https://github.com/JonasGessner/iOSOpenDev-Xcode-Templates
<br>
<br>

###Replacing Stock Control Center Sections
Stock Control Center sections can also be replaced with a custom bundle. The NIC template will ask you for which section ID should be replaced. The Section IDs that can be replaced with CCLoader are:
<br>
<br>
• com.apple.controlcenter.settings<br>
• com.apple.controlcenter.brightness<br>
• com.apple.controlcenter.media-controls<br>
• com.apple.controlcenter.air-stuff<br>
• com.apple.controlcenter.quick-launch<br>
<br>
CCLoader checks for `CCReplacingStockSectionID` in the bundle's Info.plist file. if any of the above values is given for that key then the corresponding stock section will be replaced. Otherwise the bundle will be recognized as a new section for Control Center.
<br>
<br>
A custom section that replaced a stock section has two options regarding the sections height: The custom section can return `CGFLOAT_MIN` as `sectionHeight`, in that case the height of the section that is replaced will be used. If the custom section returns anything other than `CGFLOAT_MIN` then that height will be used. This functionality is limited to iPone/iPod touch and to portrait mode. In landscape or on an iPad the height of the section that is being replaced will be used.
<br>
<br>
###iPad Support
The only feature that works on iPads is to replace stock sections. New sections cannot be added to the iPad's Control Center (as of now).
<br>
<br>
Contributing
======
Contributing to the project is much appreciated. Feel free to fork and modify the project and open pull requests.

You can contact me on Twitter: <a href="http://twitter.com/JonasGessner">@JonasGessner</a>.

License
======

Licensed under Creative Commons Attribution NonCommercial NoDerivs.

See the <a href="http://creativecommons.org/licenses/by-nc-nd/2.0/legalcode">full license</a>.

Credits
=======
© 2014, Created by Jonas Gessner
