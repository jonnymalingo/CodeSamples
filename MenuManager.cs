using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;
using Ovr;

public class MenuManager : MonoBehaviour {

	public enum Buttons { Basic = 0, Parking, Interstate, Weather, Hazard, Joyride, Controls, Exit } 
	public enum CourseButtons { Start = 0, Back } 
	public bool isMenuOpen;
	public Buttons currentSelection;
	public CourseButtons subSelection;

	public bool dPadReset = true;

	public bool isSubMenuOpen;
	GameObject[] buttons;
	GameObject[] courseButtons;
	GameObject highlighter;
	GameObject menu;
	GameObject courseMenu;
	GameObject loadingScreen;
	public OVRCameraRig oculusCam; 
	public Camera mainCam;

	// Use this for initialization
	void Start () {

		if (OVRManager.display.isPresent) {
			// Disable normal camera if Rift is connected
			this.oculusCam.gameObject.SetActive(true);
			this.mainCam.gameObject.SetActive(false);

		} else {
			this.mainCam.gameObject.SetActive(true);
			this.oculusCam.gameObject.SetActive(false);
		}

		this.menu = GameObject.Find ("Menu");
		this.courseMenu = GameObject.Find ("CourseMenu");
		this.loadingScreen = GameObject.Find ("LoadingScreen");
		Invoke ("CloseLoadingScreen", 3);

		//TODO: Change to current course
		this.currentSelection = Buttons.Basic;
		this.subSelection = CourseButtons.Start;

		HideMenu ();

		this.buttons = new GameObject[8];
		this.buttons [0] = GameObject.Find ("BasicButton");
		this.buttons [1] = GameObject.Find ("ParkingButton");
		this.buttons [2] = GameObject.Find ("InterstateButton");
		this.buttons [3] = GameObject.Find ("WeatherButton");
		this.buttons [4] = GameObject.Find ("HazardButton");
		this.buttons [5] = GameObject.Find ("JoyrideButton");
		this.buttons [6] = GameObject.Find ("ControlsButton");
		this.buttons [7] = GameObject.Find ("ExitButton");

		this.courseButtons = new GameObject[7];
		this.courseButtons [0] = GameObject.Find ("StartButton");
		this.courseButtons [1] = GameObject.Find ("BackButton"); 
	}

	void CloseLoadingScreen() {
		this.loadingScreen.GetComponent<Canvas>().enabled = false;
	}
	
	// Update is called once per frame
	void Update () {
		if (Input.GetKeyDown(KeyCode.Escape) || Input.GetButtonDown("Start")) {
			this.ToggleMenu ();
		}
		if (Input.GetKeyDown (KeyCode.F12) || Input.GetKeyDown (KeyCode.F1)) {
			OVRManager.display.RecenterPose();
		}
		if (this.isMenuOpen) {
			if (Input.GetKeyDown (KeyCode.DownArrow) || Input.GetKeyDown ("s") || (Input.GetAxis("XBoxDown") == 1 && this.dPadReset == true)) {
				this.dPadReset = false;
				this.UnhighlightButton ();
				this.highlightNextButton ();
			}
			if (Input.GetKeyDown(KeyCode.UpArrow) || Input.GetKeyDown ("w") || (Input.GetAxis("XBoxUp") == 1 && this.dPadReset == true)) {
				this.dPadReset = false;
				this.UnhighlightButton ();
				this.highlightPreviousButton ();
			}
			if (Input.GetKeyDown(KeyCode.Return) || Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.KeypadEnter) || Input.GetButtonDown("XBoxSelect") || (Input.GetAxis("XBoxRight") == 1 && this.dPadReset == true)) {
				this.dPadReset = false;
				Select ();
			}
			if ((Input.GetAxis("XBoxLeft") == 1 && this.dPadReset == true) || Input.GetButtonDown("XBoxBack")) {
				this.dPadReset = false;
				if (this.isSubMenuOpen) {
					Back ();
				} else {
					HideMenu ();
				}
			}
			if (Input.GetAxis("XBoxDown") == 0 && Input.GetAxis("XBoxUp") == 0 && Input.GetAxis("XBoxLeft") == 0 && Input.GetAxis("XBoxRight") == 0) {
				this.dPadReset = true;
			}
		}
	}

	void Select() {
		if (!this.isSubMenuOpen) {
				if (this.currentSelection == Buttons.Basic) {

				this.menu.GetComponent<Canvas>().enabled = false;
				this.courseMenu.GetComponent<Canvas>().enabled = true;

				this.UnhighlightButton ();
				this.HighlightButton (this.courseButtons[0]);
				this.subSelection = CourseButtons.Start;
				this.isSubMenuOpen = true;
			} else if (this.currentSelection == Buttons.Exit) {
				Application.Quit();
			}

		} else {
			if (this.subSelection == CourseButtons.Back) {
				this.Back();
			} else if (this.subSelection == CourseButtons.Start) {
				if (this.currentSelection == Buttons.Basic) {
					this.HideMenu();
					this.courseMenu.GetComponent<Canvas>().enabled = false;
					this.loadingScreen.GetComponent<Canvas>().enabled = true;
					Application.LoadLevel ("Clutch");
				}
			}
		}
		//TODO Play sound
	}

	void Back() {
		//Material material = Resources.Load("Menu/MenuMat", typeof(Material)) as Material;
		//this.menu.renderer.material = material;

		this.menu.GetComponent<Canvas>().enabled = true;
		this.courseMenu.GetComponent<Canvas>().enabled = false;
		
		this.UnhighlightButton ();
		this.HighlightButton (this.buttons [(int)this.currentSelection]);
		this.isSubMenuOpen = false;
		//TODO: Play sound
	}
	
	void highlightNextButton() {
		if (!this.isSubMenuOpen) {
			Buttons nextButton;
			if (this.currentSelection == Buttons.Exit) {
				nextButton = Buttons.Basic;
			} else {
				nextButton = this.currentSelection+1;
			}
			this.currentSelection = nextButton;

			this.HighlightButton (this.buttons [(int)nextButton]);
		} else {
			CourseButtons nextButton;
			if (this.subSelection == CourseButtons.Back) {
				nextButton = CourseButtons.Start;
			} else {
				nextButton = this.subSelection+1;
			}
			this.subSelection = nextButton;
			
			this.HighlightButton (this.courseButtons [(int)nextButton]);
		}
	}

	void highlightPreviousButton() {

		if (!this.isSubMenuOpen) {
			Buttons previousButton;

			if (this.currentSelection == Buttons.Basic) {
				previousButton = Buttons.Exit;
			} else {
				previousButton = this.currentSelection-1;
			}
			this.currentSelection = previousButton;

			this.HighlightButton (this.buttons [(int)previousButton]);
		} else {
			CourseButtons previousButton;

			if (this.subSelection == CourseButtons.Start) {
				previousButton = CourseButtons.Back;
			} else {
				previousButton = this.subSelection-1;
			}
			this.subSelection = previousButton;
			
			this.HighlightButton (this.courseButtons [(int)previousButton]);
		}
		//TODO: Play sound

	}

	void ToggleMenu() {
		if (this.isMenuOpen) {
			this.HideMenu ();
		} else {
			this.ShowMenu();
		}
	}

	void ShowMenu() {
		this.menu.GetComponent<Canvas>().enabled = true;
		this.isMenuOpen = true;
		//TODO: Disable Drivetrain
		//TODO: make current level the currentSelection

		this.currentSelection = Buttons.Basic;
		this.HighlightButton (this.buttons [0]);
		Back ();
	}

	void HideMenu() {
		this.menu.GetComponent<Canvas>().enabled = false;
		this.isMenuOpen = false;
		//TODO: Enable Drivetrain
	}

	void UnhighlightButton() {
		//TODO:???
	}

	void HighlightButton(GameObject button) {

		Button button2 = button.GetComponent<Button> ();
		EventSystem eventSystem = GameObject.Find("EventSystem").GetComponent<EventSystem>();
		eventSystem.SetSelectedGameObject(button2.gameObject, new BaseEventData(eventSystem));
	}

	void ShowCourseConfig(int courseIndex) {
		//TODO: Change material?
	}
	
}
