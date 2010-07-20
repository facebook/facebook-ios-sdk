/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0

 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

/**
 * Standard button which lets the user log in or out of the session.
 *
 * The button will automatically change to reflect the state of the session, showing
 * "login" if the session is not connected, and "logout" if the session is connected.
 */
@interface FBLoginButton : UIButton {
  BOOL  _isLoggedIn;
}

@property(nonatomic) BOOL isLoggedIn; 

- (void) updateImage;

@end
