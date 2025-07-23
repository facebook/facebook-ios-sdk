// (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

#import <UIKit/UIKit.h>

@interface StoryApiTableViewController : UITableViewController

@property (nonatomic, weak) IBOutlet UIBarButtonItem *targetAppButton;

- (IBAction)composerWithBackgroundImage:(id)sender;
- (IBAction)composerWithBackgroundVideo:(id)sender;

- (IBAction)storyFromAppleMusic:(id)sender;
- (IBAction)storyFromPinterest:(id)sender;
- (IBAction)storyFromSoundCloud:(id)sender;
- (IBAction)storyFromSpotifyTrack:(id)sender;
- (IBAction)storyFromSpotifyTrackWithPreview:(id)sender;
- (IBAction)storyFromSpotifyPlaylist:(id)sender;
- (IBAction)storyFromSpotifyAlbum:(id)sender;
- (IBAction)storyFromSpotifyArtist:(id)sender;
- (IBAction)storyFromSpotifyPodcast:(id)sender;
- (IBAction)storyFromSpotifyBackgroundImageActualSize:(id)sender;
- (IBAction)storyFromSpotifyBackgroundImageFullScreen:(id)sender;
- (IBAction)storyFromSpotifyBackgroundImage9by16:(id)sender;
- (IBAction)storyFromTiKToK:(id)sender;

- (IBAction)storyFromWhatsAppSinglePhoto:(id)sender;
- (IBAction)storyFromWhatsAppSingleVideo:(id)sender;
- (IBAction)storyFromWhatsAppMultipleMedia:(id)sender;
- (IBAction)storyFromWhatsAppVideoAndLink:(id)sender;
- (IBAction)storyFromWhatsAppLink:(id)sender;

- (IBAction)storyWithBackgroundImage:(id)sender;
- (IBAction)storyWithBackgroundImagePlusStickerImage:(id)sender;
- (IBAction)storyWithBackgroundVideo:(id)sender;
- (IBAction)storyWithBackgroundVideoPlusStickerImage:(id)sender;
- (IBAction)storyWithContentURL:(id)sender;
- (IBAction)storyWithStickerImage:(id)sender;

- (IBAction)selectTargetApp:(id)sender;

@end
