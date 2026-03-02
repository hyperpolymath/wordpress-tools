@0xb8d4c5f3a6e7d2c1;
# Cap'n Proto schema for Sinople WordPress data
# Provides fastest zero-copy serialization with RPC capabilities

using Cxx = import "/capnp/c++.capnp";
$Cxx.namespace("sinople");

struct Metadata {
  id @0 :UInt64;
  createdAt @1 :Int64;  # Unix timestamp
  updatedAt @2 :Int64;
  authorId @3 :UInt64;
  authorName @4 :Text;
  language @5 :Text;
  status @6 :Text;  # publish, draft, pending, private
}

struct Image {
  id @0 :UInt64;
  url @1 :Text;
  width @2 :UInt32;
  height @3 :UInt32;
  mimeType @4 :Text;
  altText @5 :Text;
  sizes @6 :List(ImageSize);
}

struct ImageSize {
  name @0 :Text;
  url @1 :Text;
  width @2 :UInt32;
  height @3 :UInt32;
}

struct CustomField {
  key @0 :Text;
  value @1 :Text;
  type @2 :Text;  # string, int, float, bool, json
}

struct Post {
  metadata @0 :Metadata;
  title @1 :Text;
  slug @2 :Text;
  content @3 :Text;
  excerpt @4 :Text;
  postType @5 :Text;
  categories @6 :List(Text);
  tags @7 :List(Text);
  emotions @8 :List(Text);
  colors @9 :List(Text);
  motifs @10 :List(Text);
  featuredImage @11 :Image;
  readingTime @12 :Float32;
  wordCount @13 :UInt32;
  customFields @14 :List(CustomField);

  # IndieWeb fields
  inReplyTo @15 :Text;
  likeOf @16 :Text;
  repostOf @17 :Text;
  bookmarkOf @18 :Text;
  syndicationLinks @19 :List(SyndicationLink);
}

struct SyndicationLink {
  service @0 :Text;
  url @1 :Text;
}

struct User {
  id @0 :UInt64;
  username @1 :Text;
  displayName @2 :Text;
  email @3 :Text;
  bio @4 :Text;
  avatarUrl @5 :Text;
  socialLinks @6 :List(SocialLink);
  postCount @7 :UInt32;
}

struct SocialLink {
  platform @0 :Text;
  url @1 :Text;
  rel @2 :Text;  # For rel=me
}

struct Comment {
  id @0 :UInt64;
  postId @1 :UInt64;
  authorName @2 :Text;
  authorEmail @3 :Text;
  authorUrl @4 :Text;
  content @5 :Text;
  createdAt @6 :Int64;
  parentId @7 :UInt64;
  status @8 :Text;
  isWebmention @9 :Bool;
}

struct Term {
  id @0 :UInt64;
  name @1 :Text;
  slug @2 :Text;
  taxonomy @3 :Text;
  description @4 :Text;
  count @5 :UInt32;
  meta @6 :List(CustomField);
}

struct Site {
  name @0 :Text;
  description @1 :Text;
  url @2 :Text;
  language @3 :Text;
  timezone @4 :Text;
  postCount @5 :UInt32;
  pageCount @6 :UInt32;
  lastUpdated @7 :Int64;
}

struct Feed {
  site @0 :Site;
  posts @1 :List(Post);
  version @2 :Text;
  generatedAt @3 :Int64;
}

# RPC interface for real-time communication
interface WordPressService {
  # Get single post
  getPost @0 (id :UInt64) -> (post :Post);

  # Stream posts (server streaming)
  streamPosts @1 (since :UInt64) -> stream (post :Post);

  # Create/update post (bidirectional streaming for bulk operations)
  updatePost @2 (post :Post) -> (result :UpdateResult);

  # Subscribe to post updates (pub/sub)
  subscribe @3 (postTypes :List(Text)) -> stream (event :PostEvent);
}

struct UpdateResult {
  union {
    success @0 :Post;
    error @1 :Error;
  }
}

struct Error {
  code @0 :UInt32;
  message @1 :Text;
}

struct PostEvent {
  eventType @0 :Text;  # created, updated, deleted
  post @1 :Post;
  timestamp @2 :Int64;
}
