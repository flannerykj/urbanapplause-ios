//
//  Copy.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct Strings {}

public extension Strings {
    static let AppTagLine = NSLocalizedString("Find great street art and artists.", comment: "")
    static func WelcomeMessage(username: String) -> String {
        let format = NSLocalizedString("Welcome, %@", comment: "")
        return String(format: format, username)
    }
    // Screen titles
    static func PhotoCarouselPaginationTitle(current: Int, total: Int) -> String {
        let format = NSLocalizedString("Photo %d of %d", comment: "")
        return String(format: format, current, total)
    }
    static let ArtistSearchPlaceholder = NSLocalizedString("Search for an artist", comment: "")
    static let NewPostScreenTitle = NSLocalizedString("New post", comment: "")
    static let AccountScreenTitle = NSLocalizedString("Account", comment: "")
    static let ReportIssueScreenTitle = NSLocalizedString("Report an issue", comment: "")
    static let MapTabItemTitle = NSLocalizedString("Map", comment: "")
    static let SearchTabItemTitle = NSLocalizedString("Search", comment: "")
    static let GalleriesTabItemTitle = NSLocalizedString("Galleries", comment: "")
    static let ProfileTabItemTitle = NSLocalizedString("Profile", comment: "")
    static let SettingsTabItemTitle = NSLocalizedString("Settings", comment: "")
    static let NewGalleryScreenTitle = NSLocalizedString("New gallery", comment: "")
    
    // Galleries
    static let MyGalleriesSectionTitle = NSLocalizedString("My collections", comment: "")
    static let OtherGalleriesSectionTitle = NSLocalizedString("Other", comment: "")

    static let ReportIssueReasonPrompt = NSLocalizedString("What is your objection to this content?", comment: "")
    static let ReportIssueSuccessMessageTitle = NSLocalizedString("Thanks for reporting the issue!", comment: "")
    static let ReportIssueSuccessMessageBody = NSLocalizedString("We've received your report and will review the content you've flagged for us.", comment: "")
    
    // Status messages
    static let NoPostsToShowMessage = NSLocalizedString("No posts to show", comment: "")
    static let NoneAddedMessage = NSLocalizedString("None added", comment: "")
    static let GettingLocationStatus = NSLocalizedString("Getting location data...", comment: "")
    static let SavingPostStatus = NSLocalizedString("Saving post...", comment: "")
    static let UploadingImagesStatus = NSLocalizedString("Uploading images...", comment: "")
    
    // Auth
    static let AuthAlreadyHaveAnAccount = NSLocalizedString("Already have an account?", comment: "")
    static let AuthDontHaveAnAccount = NSLocalizedString("Don't have an account?", comment: "")
    static func AuthResetPasswordSuccessMessage(emailAddress: String) -> String {
        let format = NSLocalizedString("An email has been sent to %@ with instructions to reset your password.", comment: "")
        return String(format: format, emailAddress)
    }
    static let SignupAgreementPrependText = NSLocalizedString("By signing up, I agree to the ", comment: "")
    static let SignupAgreementFirstJoinText = NSLocalizedString(" and ", comment: "")
    static let SignupAgreementSecondJoinText = NSLocalizedString(", including ", comment: "")
    static let Period = NSLocalizedString(".", comment: "")

    // static let CreatePostTitle = NSLocalizedString("Add a post", comment: "")
    static func BlockUserSuccessMessage(blockedUser: String?) -> String {
        let format = NSLocalizedString("%@ has been blocked", comment: "")
        return String(format: format, blockedUser ?? "This user")
    }
    // Alerts
    static let ConfirmDiscardChangesTitle = NSLocalizedString("Are you sure you want to leave?", comment: "")
    static let UnsavedChangesWarning = NSLocalizedString("You have unsaved changes that will be discarded.", comment: "")
    static let SuccessAlertTitle = NSLocalizedString("Success!", comment: "")
    static let ErrorAlertTitle = NSLocalizedString("Error", comment: "")
    static let UnknownErrorTitle = NSLocalizedString("Something went wrong", comment: "")
    static func ConfirmBlockUserAlertTitle(username: String?) -> String {
        let format = NSLocalizedString("Block %@?", comment: "")
        return String(format: format, username ?? "this user")
    }
    static let ConfirmBlockUserDetail = NSLocalizedString("You will no longer be show posts or comments from this user.", comment: "")
    static let ConfirmDeletePost = NSLocalizedString("Are you sure you want to delete this post?", comment: "")
    static let ConfirmDeleteGallery = NSLocalizedString("Are you sure you want to delete this post?", comment: "")

    static let IrreversibleActionWarning = NSLocalizedString("This cannot be undone.", comment: "")
    static let DeletePostSuccessMessage = NSLocalizedString("Your post has been deleted.", comment: "")
    
    // Post list titles
    static let RecentlyAddedPostListTitle = NSLocalizedString("Recently added", comment: "")
    static func WorkByArtist(_ artistName: String?) -> String {
        if let name = artistName {
            let format = NSLocalizedString("Work by %@", comment: "")
            return String(format: format, name)
        }
        return NSLocalizedString("Work", comment: "")
    }
    // Errors
    static let MissingPermissionsErrorMessage = NSLocalizedString("Please enable @ permissions in your Settings", comment: "")

    static let LocationServicesNotEnabledError = NSLocalizedString("Please enable location services under Settings.", comment: "")
    static func MustBeLoggedInToPerformAction(_ action: String) -> String {
        let format = NSLocalizedString("You must be logged in to %@", comment: "")
        return String(format: format, action)
    }
    // User input errors
    static let MissingEmailError = NSLocalizedString("Please enter your email.", comment: "")
    static let MissingNewUsernameError = NSLocalizedString("Please enter a username.", comment: "")
    static let MissingNewPasswordError = NSLocalizedString("Please enter a password.", comment: "")
    static let MissingUsernameError = NSLocalizedString("Please enter your username.", comment: "")
    static let MissingPasswordError = NSLocalizedString("Please enter your password.", comment: "")
    static let EmptyCommentError = NSLocalizedString("Comment cannot be empty", comment: "")

    static let MissingArtistNameError = NSLocalizedString("Please provide a name for the artist", comment: "")
    static func MaxCharacterCountError(_ characterCount: Int) -> String {
        let format = NSLocalizedString("Maximum character count is %d", comment: "")
        return String(format: format, characterCount)
    }
    static func MinCharacterCountError(_ characterCount: Int) -> String {
        let format = NSLocalizedString("Minimum character count is %d", comment: "")
        return String(format: format, characterCount)
    }
    static let MissingLocationError = NSLocalizedString("Please select a location.", comment: "")
    static let LocationLookupError = NSLocalizedString("Error occurred while reverse geocoding", comment: "")
    
    // Tab bar

    // Field Labels
    static let PasswordFieldLabel = NSLocalizedString("Password", comment: "")
    static let UsernameFieldLabel = NSLocalizedString("Username", comment: "")
    static let OptionalFieldLabel = NSLocalizedString("Optional", comment: "")
    static let NameFieldLabel = NSLocalizedString("Name", comment: "")
    static let InstagramHandleFieldLabel = NSLocalizedString("Instagram handle", comment: "")
    static let TwitterHandleFieldLabel = NSLocalizedString("Twitter handle", comment: "")
    static let WebsiteURLFieldLabel = NSLocalizedString("Website URL", comment: "")
    static let FacebookURLFieldLabel = NSLocalizedString("Facebook URL", comment: "")
    static let BioFieldLabel = NSLocalizedString("Bio", comment: "")
    static let TitleFieldLabel = NSLocalizedString("Title", comment: "")
    static let DescriptionFieldLabel = NSLocalizedString("Description", comment: "")
    static let SocialFormSectionTitle = NSLocalizedString("Social", comment: "")
    static let LocationFieldLabel = NSLocalizedString("Location", comment: "")
    static let ArtistsFieldLabel = NSLocalizedString("Artists", comment: "")
    static let LocationIsFixedFieldLabel = NSLocalizedString("Location is fixed", comment: "")
    static let SurfaceTypeFieldLabel = NSLocalizedString("Surface type", comment: "")
    static let PhotographedOnFieldLabel = NSLocalizedString("Photographed on", comment: "")
    static let PostIsVisibleFieldLabel = NSLocalizedString("Photos", comment: "")
    static let MemberSinceFieldLabel = NSLocalizedString("Member since", comment: "")
    static let ProfileCreatedOnFieldLabel = NSLocalizedString("Profile created on", comment: "")
    static let PostedByFieldLabel = NSLocalizedString("Posted by", comment: "")
    static let EmailFieldLabel = NSLocalizedString("Email address", comment: "")
    
    // Buttons
    static let DoneButtonTitle = NSLocalizedString("Done", comment: "")
    static let ShowMoreFieldsButtonTitle = NSLocalizedString("Show more fields", comment: "")
    static let ShowFewerFieldsButtonTitle = NSLocalizedString("Show fewer fields", comment: "")
    static let AddAnArtistButtonTitle = NSLocalizedString("Add an artist",
                                                          comment: "Button title for adding an artist to a post")
    static let EditProfileButtonTitle = NSLocalizedString("Edit profile", comment: "")
    static let LogInButtonTitle = NSLocalizedString("Log in", comment: "")
    static let SignUpButtonTitle = NSLocalizedString("Sign up", comment: "")
    static let ForgotPasswordButtonTitle = NSLocalizedString("I forgot my password", comment: "")
    static let SubmitButtonTitle = NSLocalizedString("Submit", comment: "")
    static let ResetPasswordButtonTitle = NSLocalizedString("Reset password", comment: "")
    static let AddPostHereButtonTitle = NSLocalizedString("Add a post here", comment: "")
    static let CancelButtonTitle = NSLocalizedString("Cancel", comment: "")
    static let OKButtonTitle = NSLocalizedString("OK", comment: "")
    static let LoadMorePostsButtonTitle = NSLocalizedString("Load more posts", comment: "")
    static let VisitedButtonTitle =  NSLocalizedString("Visited", comment: "")
    static let ApplaudedButtonTitle =  NSLocalizedString("Applauded", comment: "")
    static let ApplaudButtonTitle =  NSLocalizedString("Applaud", comment: "")
    static let MarkAsVisitedButtonTitle =  NSLocalizedString("Mark as visited", comment: "")
    static let SaveToGalleryButtonTitle = NSLocalizedString("Save to gallery", comment: "")
    static let ReportPostButtonTitle = NSLocalizedString("Report this post", comment: "")
    static let DeleteButtonTitle = NSLocalizedString("Delete", comment: "")
    static let BlockButtonTitle = NSLocalizedString("Block", comment: "Confirm request to block a user.")
    static let GetDirectionsButtonTitle = NSLocalizedString("Get directions", comment: "")
    static func BlockUserButtonTitle(username: String?) -> String {
        let format = NSLocalizedString("Block %@", comment: "")
        return String(format: format, username ?? "this user")
    }
    
    static let DiscardButtonTitle = NSLocalizedString("Discard", comment: "")
    static let GoToSettingsButtonTitle = NSLocalizedString("Go to settings", comment: "")
    static let CreateNewButtonTitle = NSLocalizedString("Create new", comment: "")
    static let TermsOfServiceLinkText = NSLocalizedString("Terms of Service", comment: "")
    static let PrivacyPolicyLinkText = NSLocalizedString("Privacy Policy", comment: "")
    static let CookieUseLinkText = NSLocalizedString("Cookie Use", comment: "")

    static let LogOutButtonTitle = NSLocalizedString("Log out", comment: "")
    static let CreateAccountButtonTitle = NSLocalizedString("Create an account", comment: "")
    // Permission types
    // Used in the context of 'Please enable [PERMISSION_TYPE] permission in Settings'
    static let LocationPermissionType = NSLocalizedString("location",
                                                          comment: "Used in the context of 'Please enable [PERMISSION_TYPE] permission in Settings'")
    static let PhotoLibraryPermissionType = NSLocalizedString("photo library",
                                                              comment: "Used in the context of 'Please enable [PERMISSION_TYPE] permission in Settings'")
    static let CameraPermissionType = NSLocalizedString("photo library",
                                                        comment: "Used in the context of 'Please enable [PERMISSION_TYPE] permission in Settings'")
    
    // Actions requiring login
    private static let authActionsComment = "Used in the context of 'You must be logged in to [ACTION]'"
    static let SaveAVisitAction = NSLocalizedString("save a visit",
                                                    comment: authActionsComment)
    static let ApplaudAPostAction = NSLocalizedString("applaud a post",
                                                      comment: authActionsComment)
    static let AddAPostAction = NSLocalizedString("add a post",
                                                  comment: authActionsComment)
    static let ViewAndCreateCollections = NSLocalizedString("view and create collections", comment: authActionsComment)
    
    
    // Time
    
    static let OneHourAgo = NSLocalizedString("one hour ago", comment: "")
}
