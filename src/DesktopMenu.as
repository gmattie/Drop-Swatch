package
{
//Imports
import com.adobe.images.PNGEncoder;
import flash.desktop.NativeApplication;
import flash.display.BitmapData;
import flash.display.NativeWindow;
import flash.display.NativeWindowDisplayState;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.Sprite;
import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.FileReference;
import flash.ui.ContextMenu;
import flash.ui.Keyboard;
import flash.utils.ByteArray;

//Class
public class DesktopMenu extends EventDispatcher
	{
	//Variables
	private var applicationMenu:NativeMenu;
	private var windowMenu:NativeMenu;
	
	private var dropSwatchMenu:NativeMenu;
	private var aboutMenuItem:NativeMenuItem;
	private var preferencesMenuItem:NativeMenuItem;
	private var quitMenuItem:NativeMenuItem;

	private var canvasMenu:NativeMenu;
	private var saveCanvasSnapshotItem:NativeMenuItem;
	private var minimizeMenuItem:NativeMenuItem;
	private var maximizeMenuItem:NativeMenuItem;
	private var fullScreenMenuItem:NativeMenuItem;
	private var restoreMenuItem:NativeMenuItem;
	
	private var swatchesMenu:NativeMenu;
	private var toggleSwatchValuesMenuItem:NativeMenuItem;
	private var removeAllSwatchesMenuItem:NativeMenuItem;
	
	private var appearancePanelMenu:NativeMenu;
	private var colorWheelMenuItem:NativeMenuItem;
	private var slidersButtonsMenuItem:NativeMenuItem;
	private var lightColorWheelMenuItem:NativeMenuItem;
	private var darkColorWheelMenuItem:NativeMenuItem;
	private var toggleTexturePanelMenuItem:NativeMenuItem;
	
	private var helpMenu:NativeMenu;
	private var dropSwatchHelpMenuItem:NativeMenuItem;
	
	//Constructor
	public function DesktopMenu()
		{
		init();
		}
		
	//Initialize
	private function init():void
		{
		var canvasMenu:NativeMenu = new NativeMenu();
		addItemsToSubmenu			(
									canvasMenu,
									canvasMenuDisplayingEventHandler,
									saveCanvasSnapshotItem = createMenuItem(createMenuItemData(saveCanvasSnapshot), "Save Canvas Snapshot", "s"),
									menuItemSeperator(),
									minimizeMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.stage.nativeWindow.minimize), "Minimize", "m"),
									maximizeMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.stage.nativeWindow.maximize), "Maximize", "k"),
									fullScreenMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.toggleDisplayState), "Full Screen", "f"),
									menuItemSeperator(),
									restoreMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.stage.nativeWindow.restore), "Restore", "r")
									);

		var swatchesMenu:NativeMenu = new NativeMenu();
		addItemsToSubmenu			(
									swatchesMenu,
									swatchesMenuDisplayingEventHandler,
									toggleSwatchValuesMenuItem = createMenuItem(createMenuItemData(toggleSwatchValues), null, "v"),
									menuItemSeperator(),
									removeAllSwatchesMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.stage.dispatchEvent, new DropSwatchEvent(DropSwatchEvent.REMOVE_ALL)), "Remove All Swatches")
									);

		var appearancePanelMenu:NativeMenu = new NativeMenu();
		addItemsToSubmenu			(
									appearancePanelMenu,
									appearancePanelMenuDisplayingEventHandler,
									colorWheelMenuItem = createMenuItem(createMenuItemData(activateColorWheelMode), "Color Wheel", "w"),
									slidersButtonsMenuItem = createMenuItem(createMenuItemData(activateColorSlidersMode), "Color Sliders & Buttons", "s"),
									menuItemSeperator(),
									lightColorWheelMenuItem = createMenuItem(createMenuItemData(activateLightColorWheelSubmode), "Light Color Wheel", "l"),
									darkColorWheelMenuItem = createMenuItem(createMenuItemData(activateDarkColorWheelSubmode), "Dark Color Wheel", "d"),
									menuItemSeperator(),
									toggleTexturePanelMenuItem = createMenuItem(createMenuItemData(toggleTexturePanel), null, "t")
									);
		
		var helpMenu:NativeMenu = new NativeMenu();
		addItemsToSubmenu			(
									helpMenu,
									helpMenuDisplayingEventHandler,
									dropSwatchHelpMenuItem = createMenuItem(createMenuItemData(showHelpDialog), "Drop Swatch Help")
									);

		if	(NativeApplication.supportsMenu)
			{
			applicationMenu = NativeApplication.nativeApplication.menu;
		
			while	(applicationMenu.items.length > 1)
					applicationMenu.removeItemAt(applicationMenu.items.length - 1);
			
			var applicationNameMenu:NativeMenuItem = applicationMenu.getItemAt(0);
			applicationNameMenu.submenu.removeItemAt(0);
			applicationNameMenu.submenu.removeItemAt(applicationNameMenu.submenu.numItems - 1);
			
			addItemsToSubmenu	(
								applicationNameMenu.submenu,
								dropSwatchMenuDisplayingEventHandler,
								aboutMenuItem = createMenuItem(createMenuItemData(showAboutDialog, null, 0), "About Drop Swatch"),
								menuItemSeperator(1),
								preferencesMenuItem = createMenuItem(createMenuItemData(showPreferencesDialog, null, 2), "Preferences...")
								);
			
			addItemsToSubmenu	(
								applicationNameMenu.submenu,
								null,
								quitMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.stage.nativeWindow.dispatchEvent, new Event(Event.CLOSING), applicationNameMenu.submenu.numItems), "Quit Drop Swatch", "q")
								);
			}
			
		if	(NativeWindow.supportsMenu)
			{
			applicationMenu = new NativeMenu();
			DropSwatch.controller.stage.nativeWindow.menu = applicationMenu;
				
			var dropSwatchMenu:NativeMenu = new NativeMenu();
			addItemsToSubmenu	(
								dropSwatchMenu,
								dropSwatchMenuDisplayingEventHandler,
								aboutMenuItem = createMenuItem(createMenuItemData(showAboutDialog), "About Drop Swatch"),
								menuItemSeperator(),
								preferencesMenuItem = createMenuItem(createMenuItemData(showPreferencesDialog), "Preferences..."),
								menuItemSeperator(),
								quitMenuItem = createMenuItem(createMenuItemData(DropSwatch.controller.stage.nativeWindow.dispatchEvent, new Event(Event.CLOSING)), "Quit Drop Swatch", "q")
								);
			
			applicationMenu.addSubmenuAt(dropSwatchMenu, 0, "Drop Swatch");
			}
			
		applicationMenu.addSubmenuAt(canvasMenu, 1, "Canvas");
		applicationMenu.addSubmenuAt(swatchesMenu, 2, "Swatches");
		applicationMenu.addSubmenuAt(appearancePanelMenu, 3, "Appearance Panel");
		applicationMenu.addSubmenuAt(helpMenu, 4, "Help");
		}
		
	//Add Items To Submenus
	private function addItemsToSubmenu(menu:NativeMenu, menuDisplayingEventHandler:Function = null, ...menuItems):void
		{
		for each	(var element:NativeMenuItem in menuItems)
					if	(element.data.index == -1)
						menu.addItem(element);
						else
						menu.addItemAt(element, element.data.index);
		
		if	(menuDisplayingEventHandler != null)
			menu.addEventListener(Event.DISPLAYING, menuDisplayingEventHandler);
		}
		
	//Create Menu Items
	private function createMenuItem(itemData:Object, itemLabel:String = null, itemKeyEquivalent:String = null, itemKeyEquivalentModifiers:Array = null):NativeMenuItem
		{
		var resultMenuItem:NativeMenuItem = new NativeMenuItem();
		resultMenuItem.data = itemData;
		
		if (itemLabel != null)					resultMenuItem.label = itemLabel;
		if (itemKeyEquivalent != null)			resultMenuItem.keyEquivalent = itemKeyEquivalent;
		if (itemKeyEquivalentModifiers != null)	resultMenuItem.keyEquivalentModifiers = itemKeyEquivalentModifiers;
		
		resultMenuItem.addEventListener(Event.SELECT, menuItemSelectEventHandler);
		
		return resultMenuItem; 
		}
	
	//Create Menu Item Data
	private function createMenuItemData(callBackFunction:Function, callBackArgument:* = null, index:int = -1):Object
		{
		return {callBackFunction:callBackFunction, callBackArgument:callBackArgument, index:index};
		}
		
	//Menu Item Seperator
	private function menuItemSeperator(index:int = -1):NativeMenuItem
		{
		var resultMenuItem:NativeMenuItem = new NativeMenuItem("", true);
		resultMenuItem.data = createMenuItemData(null, null, index);
		
		return resultMenuItem;
		}
				
	//Menu Item Select Event Handler
	private function menuItemSelectEventHandler(evt:Event):void
		{
		var targetData:Object = evt.currentTarget.data;
		
		if	(targetData.callBackArgument == null)
			targetData.callBackFunction();
			else
			targetData.callBackFunction(targetData.callBackArgument);
		}
		
	//Drop Swatch Menu Displaying Event Handler
	private function dropSwatchMenuDisplayingEventHandler(evt:Event):void
		{
		(NativeApplication.nativeApplication.activeWindow == AboutWindow.aboutWindow) ? aboutMenuItem.enabled = false : aboutMenuItem.enabled = true;
		(NativeApplication.nativeApplication.activeWindow == PreferencesWindow.preferencesWindow) ? preferencesMenuItem.enabled = false : preferencesMenuItem.enabled = true;
		}
		
	//Show About Dialog
	private function showAboutDialog():void
		{
		AboutWindow.aboutWindow.activate();
		}
		
	//Show Preferences Dialog
	private function showPreferencesDialog():void
		{
		PreferencesWindow.preferencesWindow.activate();
		}
		
	//Canvas Menu Displaying Event Handler
	private function canvasMenuDisplayingEventHandler(evt:Event):void
		{
		if	(DropSwatch.controller.stage.nativeWindow.displayState == NativeWindowDisplayState.MINIMIZED || DropSwatch.controller.stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE)
			{
			minimizeMenuItem.enabled = false;
			maximizeMenuItem.enabled = false;
			fullScreenMenuItem.enabled = false;
			restoreMenuItem.enabled = true;
			}
			else if	(DropSwatch.controller.stage.nativeWindow.displayState == NativeWindowDisplayState.MAXIMIZED)
					{
					minimizeMenuItem.enabled = true;
					maximizeMenuItem.enabled = false;
					fullScreenMenuItem.enabled = false;
					restoreMenuItem.enabled = true;
					}
					else
						{
						minimizeMenuItem.enabled = true;
						maximizeMenuItem.enabled = true;
						fullScreenMenuItem.enabled = true;
						restoreMenuItem.enabled = false;
						}
		}
		
	//Save Canvas Snapshot
	private function saveCanvasSnapshot():void
		{
		var bitmapData:BitmapData = new BitmapData(DropSwatch.controller.stage.stageWidth, DropSwatch.controller.stage.stageHeight);
		bitmapData.draw(DropSwatch.controller);
		var file:ByteArray = PNGEncoder.encode(bitmapData);
		
		var fileReference:FileReference = new FileReference();
		fileReference.save(file, "DropSwatchCanvas.png");
		}
		
	//Swatches Menu Displaying Event Handler
	private function swatchesMenuDisplayingEventHandler(evt:Event):void
		{
		for	(var i:uint = 0; i < DropSwatch.controller.numChildren; i++)
			if	(Object(DropSwatch.controller.getChildAt(i)).constructor == Swatch)
				{
				removeAllSwatchesMenuItem.enabled = true;
				toggleSwatchValuesMenuItem.enabled = true;
				break;
				}
				else
				{
				removeAllSwatchesMenuItem.enabled = false;
				toggleSwatchValuesMenuItem.enabled = false;
				}
				
		(Swatch.showValues) ? toggleSwatchValuesMenuItem.label = "Hide Color Values" : toggleSwatchValuesMenuItem.label = "Show Color Values";	
		}
		
	//Toggle Swatch Values
	private function toggleSwatchValues():void
		{
		DropSwatch.controller.stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.VALUES, null, NaN, null, (Swatch.showValues) ? false : true));
		}

	//Appearance Panel Menu Displaying Event Handler
	private function appearancePanelMenuDisplayingEventHandler(evt:Event):void
		{
		if	(DropSwatch.controller.appearancePanel.visible)
			{
			if	(DropSwatch.controller.appearancePanel.panelMode == AppearancePanel.COLOR_WHEEL_MODE)
				{
				colorWheelMenuItem.enabled = false;
				slidersButtonsMenuItem.enabled = true;
				
				if	(DropSwatch.controller.appearancePanel.colorWheelSubmode == AppearancePanel.COLOR_WHEEL_SUBMODE_LIGHT)
					{
					lightColorWheelMenuItem.enabled = false;
					darkColorWheelMenuItem.enabled = true;
					}
					else
					{
					lightColorWheelMenuItem.enabled = true;
					darkColorWheelMenuItem.enabled = false;
					}
				}
				else
				{
				colorWheelMenuItem.enabled = true;
				slidersButtonsMenuItem.enabled = false;
				lightColorWheelMenuItem.enabled = false;
				darkColorWheelMenuItem.enabled = false;
				}
				
			toggleTexturePanelMenuItem.enabled = true;
			}
			else
			{
			colorWheelMenuItem.enabled = false;
			slidersButtonsMenuItem.enabled = false;
			lightColorWheelMenuItem.enabled = false;
			darkColorWheelMenuItem.enabled = false;
			toggleTexturePanelMenuItem.enabled = false;
			}
			
		(DropSwatch.controller.appearancePanel.texturePanelIsCollapsed) ? toggleTexturePanelMenuItem.label = "Show Texture Panel" : toggleTexturePanelMenuItem.label = "Hide Texture Panel";
		}
		
	//Activate Color Wheel Mode
	private function activateColorWheelMode():void
		{
		DropSwatch.controller.appearancePanel.panelMode = AppearancePanel.COLOR_WHEEL_MODE;
		}
	
	//Activate Color Wheel Mode
	private function activateColorSlidersMode():void
		{
		DropSwatch.controller.appearancePanel.panelMode = AppearancePanel.COLOR_SLIDERS_MODE;
		}
		
	//Activate Color Wheel Light Submode
	private function activateLightColorWheelSubmode():void
		{
		DropSwatch.controller.appearancePanel.colorWheelSubmode = AppearancePanel.COLOR_WHEEL_SUBMODE_LIGHT;
		}
		
	//Activate Color Wheel Light Submode
	private function activateDarkColorWheelSubmode():void
		{
		DropSwatch.controller.appearancePanel.colorWheelSubmode = AppearancePanel.COLOR_WHEEL_SUBMODE_DARK;
		}
		
	//Toggle Texture Panel
	private function toggleTexturePanel():void
		{
		DropSwatch.controller.appearancePanel.texturePanelIsCollapsed = !DropSwatch.controller.appearancePanel.texturePanelIsCollapsed;
		}
		
	//Help Menu Displaying Event Handler
	private function helpMenuDisplayingEventHandler(evt:Event):void
		{
		(NativeApplication.nativeApplication.activeWindow == HelpWindow.helpWindow) ? dropSwatchHelpMenuItem.enabled = false : dropSwatchHelpMenuItem.enabled = true;
		}
		
	//Activate Help Window
	private function showHelpDialog():void
		{
		HelpWindow.helpWindow.activate();
		}
	}
}