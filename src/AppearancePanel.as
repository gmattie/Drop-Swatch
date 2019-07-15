package
{
//Imports
import com.caurina.transitions.Equations;
import com.caurina.transitions.Tweener;
import com.mattie.utils.colorUtils.ColorWheel;
import com.mattie.utils.colorUtils.ColorWheelQuality;
import com.mattie.utils.colorUtils.parseColor;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.PixelSnapping;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filters.DropShadowFilter;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.utils.Timer;

//Class
public class AppearancePanel extends DropSwatchAppearancePanel
	{
	//Constants
	public static const PREFS_PANEL_LOCATION:String = "prefsPanelPosition";
	public static const PREFS_PANEL_MODE:String = "prefsPanelMode";
	public static const PREFS_COLOR_WHEEL_SUBMODE:String = "prefsColorWheelSubmode";
	public static const PREFS_TEXTURE_PANEL_IS_COLLAPSED:String = "prefsTexturePanelIsCollapsed";
	
	public static const COLOR_WHEEL_MODE:String = "colorWheelMode";
	public static const COLOR_WHEEL_SUBMODE_LIGHT:String = "colorWheelSubmodeLight";
	public static const COLOR_WHEEL_SUBMODE_DARK:String = "colorWheelSubmodeDark";
	public static const COLOR_SLIDERS_MODE:String = "colorSlidersMode";
	public static const LOCATION_LEFT:String = "locationLeft";
	public static const LOCATION_RIGHT:String = "locationRight";
	public static const LOCATION_AUTO:String = "locationAuto";
	
	private static const TEXTURE_PANEL_EXPANSION:uint = 141;
	private static const FILTER_AMOUNT:Number = 14.0;
	private static const ANIMATION_DURATION:Number = 0.5;
	private static const ACTIVE_BUTTON_COLOR:Number = 0x555555;
	private static const INACTIVE_BUTTON_COLOR:Number = 0x333333;
	private static const DISABLED_BUTTON_ICON_COLOR:uint = 0x666666;
	private static const SLIDABLE_BUFFER:int = 10;
	
	//Properties
	private var panelModeProperty:String;
	private var colorWheelSubmodeProperty:String;
	private var panelLocationProperty:String;
	private var texturePanelIsCollapsedProperty:Boolean;
	
	//Variables
	private var expandedPanelHeight:uint;
	private var margin:uint;
	private var colorWheel:Sprite;
	private var lightWheel:Sprite;
	private var darkWheel:Sprite;
	private var currentMode:Sprite;
	private var targetMode:Sprite;
	private var currentWheel:Sprite;
	private var targetWheel:Sprite;
	private var selectedSwatch:Swatch;
	private var selectedSwatchColor:Object;
	private var targetSlider:Object;
	private var targetSliderSign:Object;
	private var targetSliderSignSibling:Object;
	private var pixelRGB:uint;
	private var sliderTimer:Timer;
	private var sliderOriginX:Number;
	private var sliderIsSlidable:Boolean;
	private var submodeButtonIsActive:Boolean;
	private var repositionPanelLocation:Boolean;
	private var colorPanelMainFrameMatrix:Matrix;
	private var texturePanelMatrix:Matrix;
	
	//Constructor
	public function AppearancePanel(panelMode:String = AppearancePanel.COLOR_WHEEL_MODE, colorWheelSubmode:String = AppearancePanel.COLOR_WHEEL_SUBMODE_LIGHT, panelLocation:String = AppearancePanel.LOCATION_LEFT, texturePanelIsCollapsed:Boolean = true)
		{
		visible = false;

		panelModeProperty = validatePropertyString(panelModeProperty, panelMode);
		colorWheelSubmodeProperty = validatePropertyString(colorWheelSubmodeProperty, colorWheelSubmode);
		panelLocationProperty = validatePropertyString(panelLocationProperty, panelLocation);
		texturePanelIsCollapsedProperty = texturePanelIsCollapsed;
		
		addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
	//Initialize
	private function init(evt:Event):void
		{
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		expandedPanelHeight = texturePanel.y + texturePanel.height + TEXTURE_PANEL_EXPANSION;
		margin = (DropSwatch.DEFAULT_STAGE_HEIGHT - expandedPanelHeight) / 2
		
		var darkWheelComponent:Sprite = new Sprite();
		darkWheelComponent.addChild(createColorWheelComponent(0x000000));
		darkWheelComponent.x -= darkWheelComponent.width / 2;
		darkWheelComponent.y -= darkWheelComponent.height / 2;	
		
		var ligthWheelComponent:Sprite = new Sprite();
		ligthWheelComponent.addChild(createColorWheelComponent(0xFFFFFF));
		ligthWheelComponent.x -= ligthWheelComponent.width / 2;
		ligthWheelComponent.y -= ligthWheelComponent.height / 2;
		
		darkWheel = new Sprite();
		darkWheel.addChild(darkWheelComponent);
		
		lightWheel = new Sprite();
		lightWheel.addChild(ligthWheelComponent);
		
		colorWheel = new Sprite();
		colorWheel.addChild(darkWheel);
		colorWheel.addChild(lightWheel);
		colorWheel.x = colorPanel.colorSliders.x;
		colorWheel.y = colorPanel.colorSliders.y;

		colorPanel.addChild(colorWheel);
		
		assignFieldTexture(texturePanel.field1, SwatchTexture.NONE);
		assignFieldTexture(texturePanel.field2, SwatchTexture.STRIPE);
		assignFieldTexture(texturePanel.field3, SwatchTexture.WOOD);
		assignFieldTexture(texturePanel.field4, SwatchTexture.SLATE);
		assignFieldTexture(texturePanel.field5, SwatchTexture.PAPER);
		
		for each	(var mouseDisabledTarget:Sprite in			[
																colorPanel.mainFrame.modeButtonIcon,
																colorPanel.mainFrame.submodeButtonIcon,
																])
																mouseDisabledTarget.mouseEnabled = false;
					
		for each	(var mouseChildrenDisabledTarget:Sprite in	[
																colorPanel.colorSliders.alphaSlider,
																colorPanel.colorSliders.redSlider,
																colorPanel.colorSliders.greenSlider,
																colorPanel.colorSliders.blueSlider
																])
					 											mouseChildrenDisabledTarget.mouseChildren = false;
		
		for each	(var mouseDownTarget:DisplayObject in		[
																colorWheel,
																colorPanel.colorSliders,
																colorPanel.mainFrame.background,
																colorPanel.mainFrame.modeButton,
																colorPanel.mainFrame.submodeButton,
																colorPanel.colorSliders.alphaSlider,
																colorPanel.colorSliders.redSlider,
																colorPanel.colorSliders.greenSlider,
																colorPanel.colorSliders.blueSlider,
																texturePanel.field1,
																texturePanel.field2,
																texturePanel.field3,
																texturePanel.field4,
																texturePanel.field5,
																texturePanel.button,
																texturePanel
																])
																mouseDownTarget.addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);

		if	(panelMode == AppearancePanel.COLOR_SLIDERS_MODE)
			{
			colorPanel.swapChildren(colorWheel, colorPanel.colorSliders);
			colorWheel.rotation = -45;
			colorWheel.alpha = 0.0;
			Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: 0.0, _color: DISABLED_BUTTON_ICON_COLOR});
			}
			else
			{
			colorPanel.colorSliders.rotation = -45;
			colorPanel.colorSliders.alpha = 0.0;
			submodeButtonIsActive = true;
			}

		if	(colorWheelSubmode == AppearancePanel.COLOR_WHEEL_SUBMODE_DARK)
			{
			colorWheel.swapChildrenAt(0, 1);
			colorWheel.getChildAt(0).rotation = -45;
			colorWheel.getChildAt(0).alpha = 0.0;
			}
		
		if	(texturePanelIsCollapsed)
			y = stage.stageHeight / 2 - (colorPanel.mainFrame.background.height * scaleY) / 2;
			else
			{
			y = stage.stageHeight / 2 - (expandedPanelHeight * scaleY) / 2;
			texturePanel.y += TEXTURE_PANEL_EXPANSION;
			}		
		
		colorPanelMainFrameMatrix = colorPanel.mainFrame.transform.matrix;
		texturePanelMatrix = texturePanel.transform.matrix;
		
		layout();



//		if	(DropSwatch.deviceIsMobile)
//			{
//			cacheAsBitmapMatrix = new Matrix();
//			cacheAsBitmap = true;
//			}


// NOTE: cacheAsBitmapMatrix increases performance, but the texture bitmaps become affected and render incorrectly on screen.
//		 of interest, the texture field bitmaps are only incorrectly rendered when the appearance panel is on the left side of the canvas.



		stage.addEventListener(DropSwatchEvent.SELECT, selectSwatchEventHandler);
		stage.addEventListener(DropSwatchEvent.COLOR, updateTextureFieldColorEventHandler);
		}

	//Create Color Wheel
	private function createColorWheelComponent(centerGradientColor:uint):Sprite
		{
		var colorWheelSprite:ColorWheel = new ColorWheel(colorPanel.colorSliders.width / 2 + 2, ColorWheelQuality.HIGH, centerGradientColor, 250);
		
		var matrix:Matrix = new Matrix();
		matrix.tx = colorWheelSprite.width / 2;
		matrix.ty = colorWheelSprite.height / 2;

		var colorWheelBitmapData:BitmapData = new BitmapData(colorWheelSprite.width, colorWheelSprite.height, true, 0x00FFFFFF);
		colorWheelBitmapData.draw(colorWheelSprite, matrix);

		var colorWheelBitmapMask:Shape = new Shape();
		colorWheelBitmapMask.graphics.beginFill(0x00FF00, 1.0);
		colorWheelBitmapMask.graphics.drawCircle(matrix.tx, matrix.ty, colorPanel.colorSliders.width / 2);
		colorWheelBitmapMask.graphics.endFill();
		
		var colorWheelBitmap:Bitmap = new Bitmap(colorWheelBitmapData, PixelSnapping.AUTO, true);
		colorWheelBitmap.mask = colorWheelBitmapMask;

		var result:Sprite = new Sprite();
		result.addChild(colorWheelBitmap);
		result.addChild(colorWheelBitmapMask);
		
		return result;
		}
		
	//Assign Field Texture
	private function assignFieldTexture(field:Sprite, texture:String):void
		{
		var fieldClass:Class = Object(field).constructor;
		
		var fieldMask:Sprite = new fieldClass;
		fieldMask.x = field.x;
		fieldMask.y = field.y;
		
		var fieldTexture:SwatchTexture = new SwatchTexture(field.height, false);
		fieldTexture.texture = texture;
		fieldTexture.x = field.width / 2;
		fieldTexture.y = field.height / 2;
		
		field.mask = fieldMask;
		field.addChild(fieldTexture);
		texturePanel.addChild(fieldMask);
		}
		
	//Mouse Event Handler
	private function mouseEventHandler(evt:MouseEvent):void
		{
		evt.stopImmediatePropagation();
		
		switch	(evt.currentTarget)
				{
				case colorWheel:								colorWheelMouseEventHandler(evt);			break;
				case colorPanel.mainFrame.modeButton:			modeButtonMouseEventHandler(evt);			break;
				case colorPanel.mainFrame.submodeButton:		submodeButtonMouseEventHandler(evt);		break;
				case texturePanel.button:						textureButtonMouseEventHandler(evt);		break;
				
				case colorPanel.colorSliders.alphaSlider:
				case colorPanel.colorSliders.redSlider:
				case colorPanel.colorSliders.greenSlider:
				case colorPanel.colorSliders.blueSlider:		colorSliderMouseEventHandler(evt);			break;
				
				case texturePanel.field1:
				case texturePanel.field2:
				case texturePanel.field3:
				case texturePanel.field4:
				case texturePanel.field5:						textureFieldMouseEventHandler(evt);
				}
		}

	//Color Wheel Mouse Event Handler
	private function colorWheelMouseEventHandler(evt:MouseEvent):void
		{
		evt.stopImmediatePropagation();
		
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		colorWheel.addEventListener(MouseEvent.MOUSE_MOVE, colorWheelMouseEventHandler);
												colorWheel.addEventListener(MouseEvent.MOUSE_UP, colorWheelMouseEventHandler);
												stage.addEventListener(MouseEvent.MOUSE_UP, colorWheelMouseEventHandler);
				
				case MouseEvent.MOUSE_MOVE:		pixelRGB = Bitmap(Sprite(Sprite(Sprite(evt.currentTarget.getChildAt(1)).getChildAt(0)).getChildAt(0)).getChildAt(0)).bitmapData.getPixel(evt.localX, evt.localY)
												stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.COLOR, selectedSwatch, (selectedSwatch.swatchColor >> 24) << 24 | pixelRGB));
				
												break;
												
				case MouseEvent.MOUSE_UP:		colorWheel.removeEventListener(MouseEvent.MOUSE_MOVE, colorWheelMouseEventHandler);
												colorWheel.removeEventListener(MouseEvent.MOUSE_UP, colorWheelMouseEventHandler);
												stage.removeEventListener(MouseEvent.MOUSE_UP, colorWheelMouseEventHandler);
				}
		}
	
	//Mode Button Mouse Event Handler
	private function modeButtonMouseEventHandler(evt:MouseEvent):void
		{
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		if	(!Tweener.isTweening(colorPanel.mainFrame.modeButtonIcon))
													{
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_OUT, modeButtonMouseEventHandler);
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_UP, modeButtonMouseEventHandler);
													
													Tweener.addTween(colorPanel.mainFrame.modeButton, {time: 0.0, _color: ACTIVE_BUTTON_COLOR});
													Tweener.addTween(colorPanel.mainFrame.modeButtonIcon, {time: 0.0, _Glow_alpha: 1.0});
													}
													
												break;
												
				case MouseEvent.MOUSE_OUT:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, modeButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, modeButtonMouseEventHandler);
												
												Tweener.addTween(colorPanel.mainFrame.modeButton, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: INACTIVE_BUTTON_COLOR});
												Tweener.addTween(colorPanel.mainFrame.modeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
												
												break;
												
				case MouseEvent.MOUSE_UP:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, modeButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, modeButtonMouseEventHandler);
												
												if	(panelModeProperty == AppearancePanel.COLOR_WHEEL_MODE)
													panelMode = AppearancePanel.COLOR_SLIDERS_MODE;
													else
													panelMode = AppearancePanel.COLOR_WHEEL_MODE;
												
												Tweener.addTween(colorPanel.mainFrame.modeButton, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: INACTIVE_BUTTON_COLOR});
												Tweener.addTween(colorPanel.mainFrame.modeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, rotation: 360});
												Tweener.addTween(colorPanel.mainFrame.modeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
				}
		}
		
	//Submode Button Mouse Event Handler
	private function submodeButtonMouseEventHandler(evt:MouseEvent):void
		{
		if	(submodeButtonIsActive)
			{
			switch	(evt.type)
					{
					case MouseEvent.MOUSE_DOWN:	if	(!Tweener.isTweening(colorPanel.mainFrame.submodeButtonIcon))
													{
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_OUT, submodeButtonMouseEventHandler);
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_UP, submodeButtonMouseEventHandler);
													
													Tweener.addTween(colorPanel.mainFrame.submodeButton, {time: 0.0, _color: ACTIVE_BUTTON_COLOR});
													Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: 0.0, _Glow_alpha: 1.0});
													}
													
												break;
													
					case MouseEvent.MOUSE_OUT:	evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, submodeButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, submodeButtonMouseEventHandler);
												
												Tweener.addTween(colorPanel.mainFrame.submodeButton, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: INACTIVE_BUTTON_COLOR});
												Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
												
												break;
					
					case MouseEvent.MOUSE_UP:	evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, submodeButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, submodeButtonMouseEventHandler);
												
												if	(colorWheel.getChildAt(1) == lightWheel)
													colorWheelSubmode = AppearancePanel.COLOR_WHEEL_SUBMODE_DARK;
													else
													colorWheelSubmode = AppearancePanel.COLOR_WHEEL_SUBMODE_LIGHT;
												
												Tweener.addTween(colorPanel.mainFrame.submodeButton, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: INACTIVE_BUTTON_COLOR});
												Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, rotation: colorPanel.mainFrame.submodeButtonIcon.rotation + 45});
												Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
					}
			}
		}
	
	//Texture Button Mouse Event Handler
	private function textureButtonMouseEventHandler(evt:MouseEvent):void
		{
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		if	(!Tweener.isTweening(texturePanel.background.fill))
													{
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_OUT, textureButtonMouseEventHandler);
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_UP, textureButtonMouseEventHandler);
													
													Tweener.addTween(texturePanel.background.fill, {time: 0.0, _color: 0xFFFFFF});
													Tweener.addTween(texturePanel.button, {time: 0.0, _Glow_alpha: 1.0});
													}
													
												break;
				
				case MouseEvent.MOUSE_OUT:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, textureButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, textureButtonMouseEventHandler);
												
												Tweener.addTween(texturePanel.background.fill, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: 0x000000});
												Tweener.addTween(texturePanel.button, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
												
												break;
				
				case MouseEvent.MOUSE_UP:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, textureButtonMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, textureButtonMouseEventHandler);
												
												texturePanelIsCollapsed = !texturePanelIsCollapsed;
													
												Tweener.addTween(texturePanel.background.fill, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: 0x000000});
												Tweener.addTween(texturePanel.button, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
				}
		}
		
	//Color Slider Mouse Event Handler
	private function colorSliderMouseEventHandler(evt:MouseEvent):void
		{
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		targetSlider = evt.currentTarget as Object;
												targetSliderSign = (evt.localX >= 0) ? targetSlider.plus : targetSlider.minus;
												targetSliderSignSibling = (evt.localX >= 0) ? targetSlider.minus : targetSlider.plus;
				
												targetSlider.addEventListener(MouseEvent.MOUSE_MOVE, colorSliderMouseEventHandler);
												targetSlider.addEventListener(MouseEvent.MOUSE_UP, colorSliderMouseEventHandler);
												stage.addEventListener(MouseEvent.MOUSE_UP, colorSliderMouseEventHandler);
												
												sliderTimer = new Timer(1000);
												sliderTimer.addEventListener(TimerEvent.TIMER, sliderTimerEventHandler);
												sliderTimer.start();
												
												sliderOriginX = evt.localX;
												
												Tweener.addTween(targetSlider.light, {time: 0.0, alpha: 1.0});
												Tweener.addTween(targetSliderSign, {time: 0.0, alpha: 1.0});
												Tweener.addTween(targetSliderSign, {time: 0.0, _Glow_alpha: 1.0});
												
												break;
												
				case MouseEvent.MOUSE_MOVE:		if	(sliderIsSlidable)
													slideColorSliderEventDisptacher(targetSlider, Math.round((sliderOriginX - evt.localX) * -1));
													else
													{
													if	(Math.abs(evt.localX - sliderOriginX) >= SLIDABLE_BUFFER)
														{
														sliderTimer.removeEventListener(TimerEvent.TIMER, sliderTimerEventHandler);
														sliderTimer.stop();
														sliderTimer = null;
														
														if	(selectedSwatch != null)
															selectedSwatchColor = parseColor(selectedSwatch.swatchColor);
														
														sliderOriginX = evt.localX;
														sliderIsSlidable = true;
														
														Tweener.addTween(targetSliderSignSibling, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 1.0, alpha: 1.0});
														}
													}
				
												break;
												
				case MouseEvent.MOUSE_UP:		targetSlider.removeEventListener(MouseEvent.MOUSE_MOVE, colorSliderMouseEventHandler);
												targetSlider.removeEventListener(MouseEvent.MOUSE_UP, colorSliderMouseEventHandler);
												stage.removeEventListener(MouseEvent.MOUSE_UP, colorSliderMouseEventHandler);
												
												if	(sliderTimer != null)
													{
													sliderTimer.removeEventListener(TimerEvent.TIMER, sliderTimerEventHandler);
													sliderTimer.stop();
													sliderTimer = null;
													}
												
												Tweener.addTween(targetSlider.light, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, alpha: 0.0});
												
												for each	(var sign:Object in [targetSliderSign, targetSliderSignSibling])
															Tweener.addTween(sign, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0, alpha: (sign == colorPanel.colorSliders.alphaSlider.minus) ? 0.4 : 0.2});
												
												if	(evt.currentTarget != stage && sliderIsSlidable == false)
													touchColorSliderEventDisptacher(targetSliderSign);
													else
													sliderIsSlidable = false;
				}
		}

	//Slider Timer Event Handler
	private function sliderTimerEventHandler(evt:TimerEvent):void
		{
		if	(evt.currentTarget.delay == 1000)	evt.currentTarget.delay = 200;
		if	(evt.currentTarget.delay > 40)		evt.currentTarget.delay -= 10;
			
		touchColorSliderEventDisptacher(targetSliderSign);
		}	
		
	//Slide Color Slider Event Dispatcher
	private function slideColorSliderEventDisptacher(targetSlider:Object, slideAmount:int):void
		{
		switch	(targetSlider)
				{
				case colorPanel.colorSliders.alphaSlider:	selectedSwatchColor.alpha	= Math.max(0, Math.min(selectedSwatchColor.alpha + slideAmount, 255));	break;
				case colorPanel.colorSliders.redSlider:		selectedSwatchColor.red		= Math.max(0, Math.min(selectedSwatchColor.red	 + slideAmount, 255));	break;
				case colorPanel.colorSliders.greenSlider:	selectedSwatchColor.green	= Math.max(0, Math.min(selectedSwatchColor.green + slideAmount, 255));	break;
				case colorPanel.colorSliders.blueSlider:	selectedSwatchColor.blue	= Math.max(0, Math.min(selectedSwatchColor.blue	 + slideAmount, 255));
				}
			
		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.COLOR, selectedSwatch, selectedSwatchColor.alpha << 24 | selectedSwatchColor.red << 16 | selectedSwatchColor.green << 8 | selectedSwatchColor.blue));
		
		switch	(targetSlider)
				{
				case colorPanel.colorSliders.alphaSlider:	selectedSwatchColor.alpha	= Math.max(0, Math.min(selectedSwatchColor.alpha - slideAmount, 255));	break;
				case colorPanel.colorSliders.redSlider:		selectedSwatchColor.red		= Math.max(0, Math.min(selectedSwatchColor.red	 - slideAmount, 255));	break;
				case colorPanel.colorSliders.greenSlider:	selectedSwatchColor.green	= Math.max(0, Math.min(selectedSwatchColor.green - slideAmount, 255));	break;
				case colorPanel.colorSliders.blueSlider:	selectedSwatchColor.blue	= Math.max(0, Math.min(selectedSwatchColor.blue	 - slideAmount, 255));
				}
		}		
					
	//Touch Color Slider Event Dispatcher
	private function touchColorSliderEventDisptacher(targetSliderSign:Object):void
		{
		selectedSwatchColor = parseColor(selectedSwatch.swatchColor);

		switch	(targetSliderSign)
				{
				case colorPanel.colorSliders.alphaSlider.minus:		selectedSwatchColor.alpha	= Math.max(0, Math.min(selectedSwatchColor.alpha - 1, 255));	break;
				case colorPanel.colorSliders.alphaSlider.plus:		selectedSwatchColor.alpha	= Math.max(0, Math.min(selectedSwatchColor.alpha + 1, 255));	break;
				case colorPanel.colorSliders.redSlider.minus:		selectedSwatchColor.red		= Math.max(0, Math.min(selectedSwatchColor.red	 - 1, 255));	break;
				case colorPanel.colorSliders.redSlider.plus:		selectedSwatchColor.red		= Math.max(0, Math.min(selectedSwatchColor.red 	 + 1, 255));	break;
				case colorPanel.colorSliders.greenSlider.minus:		selectedSwatchColor.green	= Math.max(0, Math.min(selectedSwatchColor.green - 1, 255));	break;
				case colorPanel.colorSliders.greenSlider.plus:		selectedSwatchColor.green	= Math.max(0, Math.min(selectedSwatchColor.green + 1, 255));	break;
				case colorPanel.colorSliders.blueSlider.minus:		selectedSwatchColor.blue	= Math.max(0, Math.min(selectedSwatchColor.blue	 - 1, 255));	break;
				case colorPanel.colorSliders.blueSlider.plus:		selectedSwatchColor.blue	= Math.max(0, Math.min(selectedSwatchColor.blue  + 1, 255));
				}

		stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.COLOR, selectedSwatch, selectedSwatchColor.alpha << 24 | selectedSwatchColor.red << 16 | selectedSwatchColor.green << 8 | selectedSwatchColor.blue));
		}
		
	//Texture Field Mouse Event Handler
	private function textureFieldMouseEventHandler(evt:MouseEvent):void
		{
		switch	(evt.type)
				{
				case MouseEvent.MOUSE_DOWN:		if	(
													!Tweener.isTweening(texturePanel.field1) &&
													!Tweener.isTweening(texturePanel.field2) &&
													!Tweener.isTweening(texturePanel.field3) &&
													!Tweener.isTweening(texturePanel.field4) &&
													!Tweener.isTweening(texturePanel.field5)
													)
													{
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_OUT, textureFieldMouseEventHandler);
													evt.currentTarget.addEventListener(MouseEvent.MOUSE_UP, textureFieldMouseEventHandler);
													
													Tweener.addTween(evt.currentTarget, {time: 0.0, _DropShadow_alpha: 0.0});
													Tweener.addTween(evt.currentTarget, {time: 0.0, _Glow_alpha: 1.0});
													}
													
												break;
												
				case MouseEvent.MOUSE_OUT:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, textureFieldMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, textureFieldMouseEventHandler);
												
												Tweener.addTween(evt.currentTarget, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _DropShadow_alpha: 1.0});
												Tweener.addTween(evt.currentTarget, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
												
												break;
												
				case MouseEvent.MOUSE_UP:		evt.currentTarget.removeEventListener(MouseEvent.MOUSE_OUT, textureFieldMouseEventHandler);
												evt.currentTarget.removeEventListener(MouseEvent.MOUSE_UP, textureFieldMouseEventHandler);
												
												stage.dispatchEvent(new DropSwatchEvent(DropSwatchEvent.TEXTURE, selectedSwatch, NaN, SwatchTexture(evt.currentTarget.getChildAt(1)).texture));
												
												Tweener.addTween(evt.currentTarget, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _DropShadow_alpha: 1.0});
												Tweener.addTween(evt.currentTarget, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _Glow_alpha: 0.0});
				}
		}
		
	//Select Swatch Event Handler
	private function selectSwatchEventHandler(evt:DropSwatchEvent):void
		{
		selectedSwatch = evt.swatchTarget;
		
		if	(evt.swatchTarget)
			updateTextureFieldColorEventHandler(evt);
		}
	
	//Update Texture Field Color Event Handler
	private function updateTextureFieldColorEventHandler(evt:DropSwatchEvent):void
		{
		var parsedColor:Object = parseColor(evt.swatchColor);

		var colorTransform:ColorTransform = new ColorTransform();
		colorTransform.color = parsedColor.red << 16 | parsedColor.green << 8 | parsedColor.blue;
					
		for each	(var textureField:Sprite in	[
												texturePanel.field1,
												texturePanel.field2,
												texturePanel.field3,
												texturePanel.field4,
												texturePanel.field5
												])
					{
					textureField.getChildAt(0).transform.colorTransform = colorTransform;
					textureField.alpha = parsedColor.alpha / 255;
					}
		}

	//Show
	public function show(autoLocation:String = null):void
		{
		var autoLocationSwitch:Boolean = false;
			
		if	(panelLocationProperty == AppearancePanel.LOCATION_AUTO)
			if	(autoLocation == null)
				throw new ArgumentError("\"AppearancePanel.show(autoLocation:String)\" – autoLocation parameter can not be null while AppearancePanel.panelLocation property is set as AppearancePanel.LOCATION_AUTO.");
				else
				{
				panelLocationProperty = validatePropertyString(panelLocationProperty, autoLocation);
				autoLocationSwitch = true;
				}
		
		visible = true;
		
		if	(texturePanelIsCollapsed)
			y = stage.stageHeight / 2 - colorPanel.mainFrame.height / 2 * scaleY;
			else
			y = stage.stageHeight / 2 - expandedPanelHeight / 2 * scaleY;
		
		if	(panelLocationProperty == LOCATION_LEFT)
			{
			x = -colorPanel.mainFrame.width * scaleX;
			
			if	(colorPanelMainFrameMatrix.a == -1)
				{
				colorPanelMainFrameMatrix.a = 1;
				colorPanel.mainFrame.transform.matrix = colorPanelMainFrameMatrix;
				
				texturePanelMatrix.a = 1;
				texturePanelMatrix.tx = texturePanel.x - texturePanel.width;
				texturePanelMatrix.ty = texturePanel.y;
				texturePanel.transform.matrix = texturePanelMatrix;
				}
		
			Tweener.addTween(this, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, x: 0});
			}
			else
			{
			x = stage.stageWidth;
			
			if	(colorPanelMainFrameMatrix.a == 1)
				{
				colorPanelMainFrameMatrix.a = -1;
				colorPanel.mainFrame.transform.matrix = colorPanelMainFrameMatrix;
				
				texturePanelMatrix.a = -1;
				texturePanelMatrix.tx = texturePanel.x + texturePanel.width;
				texturePanelMatrix.ty = texturePanel.y;
				texturePanel.transform.matrix = texturePanelMatrix;
				}
			
			Tweener.addTween(this, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, x: stage.stageWidth - colorPanel.mainFrame.width * scaleX});
			}
			
		if	(autoLocationSwitch)
			panelLocationProperty = validatePropertyString(panelLocationProperty, AppearancePanel.LOCATION_AUTO);
		}

	//Hide
	public function hide():void
		{
		Tweener.addTween(this, {time: ANIMATION_DURATION, transition: Equations.easeInOutCubic, x: (x <= 0) ? -colorPanel.mainFrame.width - FILTER_AMOUNT * scaleX : stage.stageWidth + FILTER_AMOUNT * scaleX, onComplete: hideCompleteHandler});
		}
		
	//Hide Complete Handler
	private function hideCompleteHandler():void
		{
		if	(repositionPanelLocation)
			{
			show(null);
			repositionPanelLocation = false;
			}
			else
			visible = false;
		}
		
	//Layout
	public function layout():void
		{
		if	(!Tweener.isTweening(this))
			{
			if	(stage.stageHeight < DropSwatch.DEFAULT_STAGE_HEIGHT)
				scaleX = scaleY = (stage.stageHeight - margin * 2) / expandedPanelHeight;
				else
				scaleX = scaleY = 1.0;
				
			if	(x <= 0)
				x = 0;
				else
				x = stage.stageWidth - colorPanel.mainFrame.width * scaleX;
				
			if	(texturePanelIsCollapsed)
				y = stage.stageHeight / 2 - colorPanel.mainFrame.height / 2 * scaleY;
				else
				y = stage.stageHeight / 2 - expandedPanelHeight / 2 * scaleY;
				
			for each	(var shadowTarget:Sprite in		[
														colorPanel.mainFrame.background,
														colorPanel.mainFrame.blackHole,
														texturePanel.background
														])
						shadowTarget.filters =			[new DropShadowFilter(0, 90, 0x000000, 1.0, FILTER_AMOUNT * scaleX, FILTER_AMOUNT * scaleY, 1.0, 3)];
						
			for each	(var glowTarget:Sprite in		[
														colorPanel.mainFrame.modeButtonIcon,
														colorPanel.mainFrame.submodeButtonIcon,
														colorPanel.colorSliders.alphaSlider.plus,
														colorPanel.colorSliders.alphaSlider.minus,
														colorPanel.colorSliders.redSlider.plus,
														colorPanel.colorSliders.redSlider.minus,
														colorPanel.colorSliders.greenSlider.plus,
														colorPanel.colorSliders.greenSlider.minus,
														colorPanel.colorSliders.blueSlider.plus,
														colorPanel.colorSliders.blueSlider.minus,
														texturePanel.button
														])
						glowTarget.filters = 			[new GlowFilter(0xFFFFFF, 0.0, FILTER_AMOUNT * scaleX, FILTER_AMOUNT * scaleY, 2, 3)];
						
			for each	(var shadowGlowTarget:Sprite in [
														texturePanel.field1,
														texturePanel.field2,
														texturePanel.field3,
														texturePanel.field4,
														texturePanel.field5
														])
						shadowGlowTarget.filters = 		[
														new DropShadowFilter(0, 90, 0x000000, 1.0, FILTER_AMOUNT * scaleX, FILTER_AMOUNT * scaleY, 1.0, 3),
														new GlowFilter(0xFFFFFF, 0.0, FILTER_AMOUNT * scaleX, FILTER_AMOUNT * scaleY, 2, 3)
														];
			}
		}
		
	//Validate Property Value
	private function validatePropertyString(property:String, value:String):String
		{
		switch	(property)
				{
				case panelModeProperty:				if	(value != AppearancePanel.COLOR_WHEEL_MODE && value != AppearancePanel.COLOR_SLIDERS_MODE)
														throw new ArgumentError("The set value of \"" + value + "\" for \"AppearancePanel.panelMode\" property is not valid.");
													
													break;
													
				case colorWheelSubmodeProperty:		if	(value != AppearancePanel.COLOR_WHEEL_SUBMODE_LIGHT && value != AppearancePanel.COLOR_WHEEL_SUBMODE_DARK)
														throw new ArgumentError("The set value of \"" + value + "\" for \"AppearancePanel.colorWheelSubmode\" property is not valid.");
													
													break;
													
				case panelLocationProperty:			if	(value != AppearancePanel.LOCATION_LEFT && value != AppearancePanel.LOCATION_RIGHT && value != AppearancePanel.LOCATION_AUTO)
														throw new ArgumentError("The set value of \"" + value + "\" for \"AppearancePanel.panelLocation\" property is not valid.");
				}
		
		return value;
		}
		
	//Panel Mode Setter
	public function set panelMode(value:String):void
		{
		if	(panelModeProperty != value	&&	!Tweener.isTweening(currentMode) && !Tweener.isTweening(targetMode) && visible)
			{
			panelModeProperty = validatePropertyString(panelModeProperty, value);
			
			currentMode = colorPanel.getChildAt(Math.max(colorPanel.getChildIndex(colorWheel), colorPanel.getChildIndex(colorPanel.colorSliders))) as Sprite;
			targetMode = colorPanel.getChildAt(Math.min(colorPanel.getChildIndex(colorWheel), colorPanel.getChildIndex(colorPanel.colorSliders))) as Sprite;
			
			Tweener.addTween(currentMode, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, rotation: 45, alpha: 0.0});
			Tweener.addTween(targetMode, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, rotation: 0, alpha: 1.0, onComplete: panelModeCompleteHandler, onCompleteParams: [currentMode]});
			
			if	(currentMode == colorWheel)
				{
				submodeButtonIsActive = false;
				Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: DISABLED_BUTTON_ICON_COLOR});
				}
				else
				Tweener.addTween(colorPanel.mainFrame.submodeButtonIcon, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, _color: 0xFFFFFF});
			}
		}
		
	//Panel Mode Complete Handler
	private function panelModeCompleteHandler(targetSprite:Sprite):void
		{
		colorPanel.swapChildren(colorWheel, colorPanel.colorSliders);
		targetSprite.rotation = -45;

		if	(targetSprite == colorPanel.colorSliders)
			submodeButtonIsActive = true;
		}
		
	//Panel Mode Getter
	public function get panelMode():String
		{
		return panelModeProperty;
		}
		
	//Color Wheel Submode Setter
	public function set colorWheelSubmode(value:String):void
		{
		if	(colorWheelSubmodeProperty != value	&& panelModeProperty == AppearancePanel.COLOR_WHEEL_MODE &&	!Tweener.isTweening(currentWheel) && !Tweener.isTweening(targetWheel) && visible)
			{
			colorWheelSubmodeProperty = validatePropertyString(colorWheelSubmodeProperty, value);
			
			currentWheel = colorWheel.getChildAt(1) as Sprite;
			targetWheel = colorWheel.getChildAt(0) as Sprite;
			targetWheel.alpha = 1.0;
			
			Tweener.addTween(currentWheel, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, alpha: 0.0, rotation: 45});
			Tweener.addTween(targetWheel, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, rotation: 0, onComplete: colorWheelSubmodeCompleteHandler, onCompleteParams: [currentWheel]});
			}
		}
		
	//Color Wheel Submode Change Complete Handler
	private function colorWheelSubmodeCompleteHandler(targetSprite:Sprite):void
		{
		colorWheel.swapChildrenAt(0, 1);
		targetSprite.rotation = -45;
		}
		
	//Color Wheel Submode Getter
	public function get colorWheelSubmode():String
		{
		return colorWheelSubmodeProperty;
		}
		
	//Panel Location Setter
	public function set panelLocation(value:String):void
		{
		panelLocationProperty = validatePropertyString(panelLocationProperty, value);
		
		if	(visible && panelLocationProperty != LOCATION_AUTO)
			if	((panelLocationProperty == LOCATION_LEFT && x != 0) || (panelLocationProperty == LOCATION_RIGHT && Math.round(x) != Math.round(stage.stageWidth - colorPanel.mainFrame.width * scaleX)))
				{
				repositionPanelLocation = true;
				hide();
				}
		}
		
	//Panel Location getter
	public function get panelLocation():String
		{
		return panelLocationProperty;
		}
		
	//Texture Panel Is Collapsed Setter
	public function set texturePanelIsCollapsed(value:Boolean):void
		{
		if	(visible && !Tweener.isTweening(texturePanel) && !Tweener.isTweening(this))
			{
			if	(texturePanelIsCollapsed)
				{
				Tweener.addTween(this, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, y: stage.stageHeight / 2 - (expandedPanelHeight * scaleY) / 2});
				Tweener.addTween(texturePanel, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, y: texturePanel.y + TEXTURE_PANEL_EXPANSION});
				}
				else
				{
				Tweener.addTween(this, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, y: stage.stageHeight / 2 - (colorPanel.mainFrame.background.height * scaleY) / 2});
				Tweener.addTween(texturePanel, {time: ANIMATION_DURATION, transition: Equations.easeInOutQuad, y: texturePanel.y - TEXTURE_PANEL_EXPANSION});
				}
													
			texturePanelIsCollapsedProperty = value;
			}
		}
		
	//Texture Panel Is Collapsed Getter
	public function get texturePanelIsCollapsed():Boolean
		{
		return texturePanelIsCollapsedProperty;
		}
	}
}