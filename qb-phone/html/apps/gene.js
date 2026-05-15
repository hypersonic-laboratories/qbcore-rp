const GeneApp = {
    template: `
        <div style="height: 100%">

            <!-- ── Profile view ── -->
            <div v-if="geneProfileHandle !== null" class="gene-screen">
                <div class="gene-top">
                    <div class="gene-top-row">
                        <button type="button" aria-label="Back" class="gene-icon-button" @click="geneProfileHandle = null">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="gene-eyebrow">H</div>
                            <div class="gene-view-title">Profile</div>
                        </div>
                    </div>
                </div>
                <div class="gene-feed" v-if="geneProfileUser">
                    <div class="gene-profile-card">
                        <div class="gene-post-avatar gene-profile-avatar" :style="{ background: geneAvatarColor(geneProfileHandle).bg, color: geneAvatarColor(geneProfileHandle).color }">{{ geneProfileHandle.charAt(0).toUpperCase() }}</div>
                        <div class="gene-profile-info">
                            <div class="gene-profile-name">{{ geneProfileHandle }}</div>
                            <div class="gene-post-handle">{{ geneProfileUser.handle }}</div>
                            <div class="gene-profile-bio">{{ geneProfileUser.bio }}</div>
                            <div class="gene-profile-stats">
                                <span><strong>{{ geneProfileUser.followers }}</strong> followers</span>
                                <span><strong>{{ geneProfileUser.following_count }}</strong> following</span>
                                <span><strong>{{ geneProfilePosts.length }}</strong> posts</span>
                            </div>
                        </div>
                        <button type="button" :class="['gene-follow-pill', 'gene-profile-follow-btn', geneProfileUser.following ? 'gene-follow-pill-active' : '']" @click="toggleFollow(geneProfileHandle)">{{ geneProfileUser.following ? 'Following' : 'Follow' }}</button>
                    </div>
                    <div class="gene-thread-divider">
                        <span class="gene-thread-divider-label">Posts</span>
                    </div>
                    <template v-if="geneProfilePosts.length">
                        <div v-for="post in geneProfilePosts" :key="post.id" class="gene-post-card">
                            <div class="gene-post-header">
                                <button type="button" class="gene-avatar-btn" @click="openProfile(post.author)">
                                    <div class="gene-post-avatar" :style="{ background: geneAvatarColor(post.author).bg, color: geneAvatarColor(post.author).color }">{{ post.author.charAt(0).toUpperCase() }}</div>
                                </button>
                                <div class="gene-post-meta">
                                    <div class="gene-post-author-row">
                                        <button type="button" class="gene-author-link" @click="openProfile(post.author)">{{ post.author }}</button>
                                        <span class="gene-post-handle">{{ post.handle }}</span>
                                    </div>
                                    <div class="gene-post-time">{{ post.time }}</div>
                                </div>
                                <button v-if="post.author === 'You' || post.author === playerName" type="button" class="gene-post-delete" aria-label="Delete post" @click="deletePost(post.id)">
                                    <i data-lucide="trash-2" class="gene-post-delete-icon"></i>
                                </button>
                            </div>
                            <div class="gene-post-content">{{ post.content }}</div>
                            <div v-if="post.image" class="gene-post-image-wrap">
                                <img :src="post.image" alt="Post image" class="gene-post-image" @error="e => e.target.parentElement.style.display='none'" />
                            </div>
                            <div class="gene-post-actions">
                                <button type="button" :class="['gene-action-btn', post.liked ? 'gene-action-liked' : '']" @click="toggleLike(post.id)">
                                    <i data-lucide="heart" class="gene-action-icon"></i>
                                    <span>{{ post.likes }}</span>
                                </button>
                                <button type="button" :class="['gene-action-btn', post.reposted ? 'gene-action-reposted' : '']" @click="toggleRepost(post.id)">
                                    <i data-lucide="repeat-2" class="gene-action-icon"></i>
                                    <span>{{ post.reposts }}</span>
                                </button>
                                <button type="button" class="gene-action-btn" @click="openThread(post.id)">
                                    <i data-lucide="message-square" class="gene-action-icon"></i>
                                    <span>{{ post.comments.length }}</span>
                                </button>
                            </div>
                        </div>
                    </template>
                    <div v-else class="phone-empty-state">No posts yet.</div>
                </div>
            </div>

            <!-- ── Thread view ── -->
            <div v-else-if="geneThreadPost !== null" class="gene-screen">
                <div class="gene-top">
                    <div class="gene-top-row">
                        <button type="button" aria-label="Back to feed" class="gene-icon-button" @click="geneThreadPostId = null; threadCommentDraft = ''">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="gene-eyebrow">H</div>
                            <div class="gene-view-title">Thread</div>
                        </div>
                    </div>
                </div>
                <div class="gene-feed">
                    <div class="gene-post-card gene-post-card-thread">
                        <div class="gene-post-header">
                            <button type="button" class="gene-avatar-btn" @click="openProfile(geneThreadPost.author)">
                                <div class="gene-post-avatar" :style="{ background: geneAvatarColor(geneThreadPost.author).bg, color: geneAvatarColor(geneThreadPost.author).color }">{{ geneThreadPost.author.charAt(0).toUpperCase() }}</div>
                            </button>
                            <div class="gene-post-meta">
                                <div class="gene-post-author-row">
                                    <button type="button" class="gene-author-link" @click="openProfile(geneThreadPost.author)">{{ geneThreadPost.author }}</button>
                                    <span class="gene-post-handle">{{ geneThreadPost.handle }}</span>
                                    <template v-if="USERS[geneThreadPost.author] && geneThreadPost.author !== 'You'">
                                        <button type="button" :class="['gene-follow-pill', USERS[geneThreadPost.author].following ? 'gene-follow-pill-active' : '']" @click.stop="toggleFollow(geneThreadPost.author)">{{ USERS[geneThreadPost.author].following ? 'Following' : 'Follow' }}</button>
                                    </template>
                                </div>
                                <div class="gene-post-time">{{ geneThreadPost.time }}</div>
                            </div>
                            <button v-if="geneThreadPost.author === 'You' || geneThreadPost.author === playerName" type="button" class="gene-post-delete" aria-label="Delete post" @click="deletePost(geneThreadPost.id)">
                                <i data-lucide="trash-2" class="gene-post-delete-icon"></i>
                            </button>
                        </div>
                        <div class="gene-post-content">{{ geneThreadPost.content }}</div>
                        <div v-if="geneThreadPost.image" class="gene-post-image-wrap">
                            <img :src="geneThreadPost.image" alt="Post image" class="gene-post-image" @error="e => e.target.parentElement.style.display='none'" />
                        </div>
                        <div class="gene-post-actions">
                            <button type="button" :class="['gene-action-btn', geneThreadPost.liked ? 'gene-action-liked' : '']" @click="toggleLike(geneThreadPost.id)">
                                <i data-lucide="heart" class="gene-action-icon"></i>
                                <span>{{ geneThreadPost.likes }}</span>
                            </button>
                            <button type="button" :class="['gene-action-btn', geneThreadPost.reposted ? 'gene-action-reposted' : '']" @click="toggleRepost(geneThreadPost.id)">
                                <i data-lucide="repeat-2" class="gene-action-icon"></i>
                                <span>{{ geneThreadPost.reposts }}</span>
                            </button>
                            <button type="button" class="gene-action-btn">
                                <i data-lucide="message-square" class="gene-action-icon"></i>
                                <span>{{ geneThreadPost.comments.length }}</span>
                            </button>
                        </div>
                    </div>

                    <div class="gene-thread-divider">
                        <span class="gene-thread-divider-label">{{ geneThreadPost.comments.length }} comment{{ geneThreadPost.comments.length !== 1 ? 's' : '' }}</span>
                    </div>

                    <template v-if="geneThreadPost.comments.length">
                        <div v-for="comment in geneThreadPost.comments" :key="comment.id" class="gene-comment-card">
                            <div class="gene-post-avatar gene-comment-avatar" :style="{ background: geneAvatarColor(comment.author).bg, color: geneAvatarColor(comment.author).color }">{{ comment.author.charAt(0).toUpperCase() }}</div>
                            <div class="gene-comment-body">
                                <div class="gene-comment-header">
                                    <span class="gene-post-author">{{ comment.author }}</span>
                                    <span class="gene-post-handle">{{ comment.handle }}</span>
                                    <span class="gene-post-time">{{ comment.time }}</span>
                                </div>
                                <div class="gene-comment-text">{{ comment.text }}</div>
                            </div>
                        </div>
                    </template>
                    <div v-else class="phone-empty-state">No comments yet. Be the first!</div>
                </div>
                <div class="gene-reply-composer">
                    <div class="gene-post-avatar gene-composer-avatar" :style="{ background: geneAvatarColor('You').bg, color: geneAvatarColor('You').color }">Y</div>
                    <input v-model="threadCommentDraft" placeholder="Add a comment…" class="gene-reply-input" @keyup.enter="addComment(geneThreadPostId, threadCommentDraft)" />
                    <button type="button" class="gene-send-button" aria-label="Send comment" @click="addComment(geneThreadPostId, threadCommentDraft)">
                        <i data-lucide="send-horizontal" class="gene-send-icon"></i>
                    </button>
                </div>
            </div>

            <!-- ── Feed view ── -->
            <div v-else class="gene-screen">
                <div class="gene-top">
                    <div class="gene-top-row">
                        <button type="button" aria-label="Back to home" class="gene-icon-button" @click="closeGene">
                            <i data-lucide="arrow-left" style="width:1.25rem;height:1.25rem"></i>
                        </button>
                        <div class="phone-app-top-copy">
                            <div class="gene-eyebrow">H</div>
                            <div class="gene-view-title">Feed</div>
                        </div>
                    </div>
                    <div class="gene-search-wrap">
                        <i data-lucide="search" class="gene-search-icon"></i>
                        <input v-model="geneSearch" placeholder="Search posts" class="gene-search-input" />
                    </div>
                </div>

                <div class="gene-feed">
                    <template v-if="filteredPosts.length">
                        <div v-for="post in filteredPosts" :key="post.id" class="gene-post-card">
                            <div class="gene-post-header">
                                <button type="button" class="gene-avatar-btn" @click="openProfile(post.author)">
                                    <div class="gene-post-avatar" :style="{ background: geneAvatarColor(post.author).bg, color: geneAvatarColor(post.author).color }">{{ post.author.charAt(0).toUpperCase() }}</div>
                                </button>
                                <div class="gene-post-meta">
                                    <div class="gene-post-author-row">
                                        <button type="button" class="gene-author-link" @click="openProfile(post.author)">{{ post.author }}</button>
                                        <span class="gene-post-handle">{{ post.handle }}</span>
                                        <template v-if="USERS[post.author] && post.author !== 'You'">
                                            <button type="button" :class="['gene-follow-pill', USERS[post.author].following ? 'gene-follow-pill-active' : '']" @click.stop="toggleFollow(post.author)">{{ USERS[post.author].following ? 'Following' : 'Follow' }}</button>
                                        </template>
                                    </div>
                                    <div class="gene-post-time">{{ post.time }}</div>
                                </div>
                                <button v-if="post.author === 'You' || post.author === playerName" type="button" class="gene-post-delete" aria-label="Delete post" @click="deletePost(post.id)">
                                    <i data-lucide="trash-2" class="gene-post-delete-icon"></i>
                                </button>
                            </div>
                            <div class="gene-post-content">{{ post.content }}</div>
                            <div v-if="post.image" class="gene-post-image-wrap">
                                <img :src="post.image" alt="Post image" class="gene-post-image" @error="e => e.target.parentElement.style.display='none'" />
                            </div>
                            <div class="gene-post-actions">
                                <button type="button" :class="['gene-action-btn', post.liked ? 'gene-action-liked' : '']" @click="toggleLike(post.id)">
                                    <i data-lucide="heart" class="gene-action-icon"></i>
                                    <span>{{ post.likes }}</span>
                                </button>
                                <button type="button" :class="['gene-action-btn', post.reposted ? 'gene-action-reposted' : '']" @click="toggleRepost(post.id)">
                                    <i data-lucide="repeat-2" class="gene-action-icon"></i>
                                    <span>{{ post.reposts }}</span>
                                </button>
                                <button type="button" class="gene-action-btn" @click="openThread(post.id)">
                                    <i data-lucide="message-square" class="gene-action-icon"></i>
                                    <span>{{ post.comments.length }}</span>
                                </button>
                            </div>
                        </div>
                    </template>
                    <div v-else class="phone-empty-state">No posts yet.</div>
                </div>

                <button type="button" class="gene-fab" aria-label="New post" @click="showGeneComposer = true">
                    <i data-lucide="pencil" class="gene-fab-icon"></i>
                </button>

                <!-- Compose sheet -->
                <div v-if="showGeneComposer" class="gene-compose-backdrop" @click.self="cancelCompose">
                    <div class="gene-compose-sheet">
                        <div class="gene-compose-sheet-handle"></div>
                        <div class="gene-compose-sheet-header">
                            <button type="button" class="gene-compose-sheet-cancel" @click="cancelCompose">Cancel</button>
                            <span class="gene-compose-sheet-title">New Post</span>
                            <button type="button" class="gene-compose-sheet-post" @click="createPost" :disabled="!newPostContent.trim()">Post</button>
                        </div>
                        <div class="gene-compose-sheet-body">
                            <div class="gene-post-avatar" :style="{ background: geneAvatarColor('You').bg, color: geneAvatarColor('You').color }">Y</div>
                            <div class="gene-compose-sheet-inputs">
                                <textarea v-model="newPostContent" placeholder="What's on your mind?" class="gene-compose-sheet-textarea" rows="4"></textarea>
                                <input v-model="newPostImageUrl" placeholder="Image URL (optional)" class="gene-compose-sheet-image-input" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div>
    `,

    emits: ["navigate"],

    setup(props, { emit }) {
        const { ref, computed, onMounted } = Vue;
        const { USERS, POSTS, playerName } = window.PhoneStore;

        const geneSearch = ref("");
        const showGeneComposer = ref(false);
        const newPostContent = ref("");
        const newPostImageUrl = ref("");
        const geneThreadPostId = ref(null);
        const threadCommentDraft = ref("");
        const geneProfileHandle = ref(null);

        function geneAvatarColor(author) {
            const colors = [
                { bg: "rgb(249 168 212)", color: "rgb(131 24 67)" },
                { bg: "rgb(147 197 253)", color: "rgb(30 64 175)" },
                { bg: "rgb(110 231 183)", color: "rgb(6 78 59)" },
                { bg: "rgb(253 186 116)", color: "rgb(124 45 18)" },
                { bg: "rgb(196 181 253)", color: "rgb(76 29 149)" },
            ];
            const idx = (author.charCodeAt(0) || 0) % colors.length;
            return colors[idx];
        }

        const filteredPosts = computed(() => {
            const q = geneSearch.value.trim().toLowerCase();
            return POSTS.filter((p) => p.author.toLowerCase().includes(q) || p.content.toLowerCase().includes(q));
        });

        const geneThreadPost = computed(() => (geneThreadPostId.value === null ? null : POSTS.find((p) => p.id === geneThreadPostId.value) || null));

        const geneProfileUser = computed(() => (geneProfileHandle.value ? USERS[geneProfileHandle.value] || null : null));

        const geneProfilePosts = computed(() => (geneProfileHandle.value ? POSTS.filter((p) => p.author === geneProfileHandle.value) : []));

        onMounted(() => hEvent("loadFeed"));

        function cancelCompose() {
            showGeneComposer.value = false;
            newPostContent.value = "";
            newPostImageUrl.value = "";
        }

        function createPost() {
            if (!newPostContent.value.trim()) return;
            const content = newPostContent.value.trim();
            const image = newPostImageUrl.value.trim();
            cancelCompose();
            hEvent("createPost", { content, image });
        }

        function toggleLike(id) {
            const post = POSTS.find((p) => p.id === id);
            if (!post) return;
            post.liked = !post.liked;
            post.likes += post.liked ? 1 : -1;
            hEvent("likePost", { postId: id, liked: post.liked });
        }

        function toggleRepost(id) {
            const post = POSTS.find((p) => p.id === id);
            if (!post) return;
            post.reposted = !post.reposted;
            post.reposts += post.reposted ? 1 : -1;
            hEvent("repostPost", { postId: id, reposted: post.reposted });
        }

        function toggleFollow(authorName) {
            const user = USERS[authorName];
            if (!user) return;
            user.following = !user.following;
            user.followers += user.following ? 1 : -1;
            hEvent("followUser", { handle: authorName, targetPhone: user.phone || "", following: user.following });
        }

        function deletePost(id) {
            const idx = POSTS.findIndex((p) => p.id === id);
            if (idx !== -1) POSTS.splice(idx, 1);
            if (geneThreadPostId.value === id) geneThreadPostId.value = null;
            hEvent("deletePost", { postId: id });
        }

        function addComment(postId, text) {
            if (!text.trim()) return;
            hEvent("addComment", { postId, text: text.trim() });
            threadCommentDraft.value = "";
        }

        function openThread(id) {
            geneThreadPostId.value = id;
            threadCommentDraft.value = "";
        }

        function openProfile(authorName) {
            if (USERS[authorName]) geneProfileHandle.value = authorName;
        }

        function closeGene() {
            cancelCompose();
            geneSearch.value = "";
            geneThreadPostId.value = null;
            geneProfileHandle.value = null;
            emit("navigate", "home");
        }

        return {
            USERS,
            POSTS,
            playerName,
            geneSearch,
            showGeneComposer,
            newPostContent,
            newPostImageUrl,
            geneThreadPostId,
            threadCommentDraft,
            geneProfileHandle,
            filteredPosts,
            geneThreadPost,
            geneProfileUser,
            geneProfilePosts,
            geneAvatarColor,
            cancelCompose,
            createPost,
            toggleLike,
            toggleRepost,
            toggleFollow,
            deletePost,
            addComment,
            openThread,
            openProfile,
            closeGene,
        };
    },
};
