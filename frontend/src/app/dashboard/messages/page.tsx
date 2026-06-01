"use client";

import React, { useState, useEffect, useRef } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  Search,
  Send,
  MoreVertical,
  User,
  MessageCircle,
  Clock,
  CheckCheck,
  Phone,
  Video,
  Info,
  ChevronLeft,
  Loader2,
  Plus
} from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { getSocket } from "@/lib/socket";
import { useAuth } from "@/components/shared/AuthProvider";

export default function MessagesPage() {
  const { t, isAr } = useTranslation();
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [selectedChat, setSelectedChat] = useState<any>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [messageText, setMessageText] = useState("");
  const [isSearchMode, setIsSearchMode] = useState(false);
  const [selectedImage, setSelectedImage] = useState<string | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleAttachmentClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const file = e.target.files[0];
      if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onloadend = () => {
          setSelectedImage(reader.result as string);
        };
        reader.readAsDataURL(file);
      } else {
        alert(isAr ? "سيتم دعم إرسال المرفقات قريباً!" : "Attachments will be supported soon!");
      }
      e.target.value = "";
    }
  };

  const removeSelectedImage = () => {
    setSelectedImage(null);
  };

  // Queries
  const { data: conversations, isLoading: loadingChats } = useQuery({
    queryKey: ["conversations"],
    queryFn: async () => (await api.get("/chat/conversations")).data.data
  });

  const { data: messages, isLoading: loadingMessages } = useQuery({
    queryKey: ["messages", selectedChat?.id],
    queryFn: async () => {
      if (!selectedChat?.id) return [];
      return (await api.get(`/chat/messages/${selectedChat.id}`)).data.data;
    },
    enabled: !!selectedChat?.id
  });

  const { data: searchResults, isFetching: searchingContacts } = useQuery({
    queryKey: ["contacts", searchQuery],
    queryFn: async () => (await api.get(`/chat/contacts?q=${searchQuery}`)).data.data,
    enabled: isSearchMode && searchQuery.length > 1
  });

  // Mutation
  const sendMutation = useMutation({
    mutationFn: async (payload: { content: string, receiverId?: string, conversationId?: string }) =>
      api.post("/chat/send", payload),
    onSuccess: (res) => {
      setMessageText("");
      setSelectedImage(null);
      queryClient.invalidateQueries({ queryKey: ["messages", selectedChat?.id] });
      queryClient.invalidateQueries({ queryKey: ["conversations"] });

      // If we just started a new chat, update selectedChat with the real conversation object
      if (isSearchMode) {
        setIsSearchMode(false);
        setSearchQuery("");
      }
    }
  });

  // Socket setup
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const handleNewMessage = (msg: any) => {
      if (msg.conversationId === selectedChat?.id) {
        queryClient.setQueryData(["messages", selectedChat.id], (old: any) => [...(old || []), msg]);
      }
      queryClient.invalidateQueries({ queryKey: ["conversations"] });
    };

    socket.on("chat:message", handleNewMessage);
    return () => {
      socket.off("chat:message", handleNewMessage);
    };
  }, [selectedChat, queryClient]);

  // Scroll to bottom
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const handleSendMessage = () => {
    if (!messageText.trim() && !selectedImage) return;

    let content = messageText.trim();
    if (selectedImage) {
      content = `IMAGE:${selectedImage}${content ? `\n${content}` : ''}`;
      setSelectedImage(null);
    }

    if (isSearchMode && selectedChat?.entityId) {
      // Starting a new conversation from contact search - use entityId
      sendMutation.mutate({ content, receiverId: selectedChat.entityId });
    } else if (isSearchMode && selectedChat?.id) {
      // Fallback to id if entityId not available
      sendMutation.mutate({ content, receiverId: selectedChat.id });
    } else {
      // Continuing existing conversation
      sendMutation.mutate({ content, conversationId: selectedChat.id });
    }
    setMessageText("");
  };

  const handleSelectContact = (contact: any) => {
    // Check if we already have a conversation with this person using entityId
    const existing = conversations?.find((c: any) => c.otherUser.id === contact.id);
    if (existing) {
      setSelectedChat(existing);
      setIsSearchMode(false);
    } else {
      // Use entityId for new conversations
      const contactWithEntityId = {
        ...contact,
        entityId: contact.entityId || contact.id
      };
      setSelectedChat(contactWithEntityId); // Temporary contact object
      setIsSearchMode(true);
    }
    setSearchQuery("");
  };

  return (
    <div className="messages-module-premium" dir={isAr ? "rtl" : "ltr"}>
      <div className="messages-container-luxe card-glass-ultra">
        {/* Sidebar: Chats & Contacts */}
        <div className="chat-sidebar-luxe">
          <div className="sidebar-header-luxe">
            <div className="header-top">
              <h2>{isAr ? "المحادثات" : "Messages"}</h2>
              <button className="btn-new-chat" onClick={() => { setIsSearchMode(true); setSelectedChat(null); }}>
                <Plus size={18} />
              </button>
            </div>

            <div className="search-wrapper-premium">
              <Search size={16} className="search-icon" />
              <input
                type="text"
                placeholder={isAr ? "ابحث عن شخص..." : "Search people..."}
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  if (e.target.value) setIsSearchMode(true);
                  else if (!selectedChat) setIsSearchMode(false);
                }}
              />
            </div>
          </div>

          <div className="chat-list-luxe custom-scrollbar">
            {isSearchMode ? (
              <div className="search-results-luxe">
                <div className="section-label">
                  {searchingContacts ? (
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "6px" }}>
                      <Loader2 className="animate-spin" size={14} />
                      {isAr ? "جاري البحث..." : "Searching..."}
                    </div>
                  ) : (
                    isAr ? "نتائج البحث" : "Search Results"
                  )}
                </div>
                {searchResults?.map((contact: any) => (
                  <div key={contact.entityId || contact.id} className="chat-item-luxe" onClick={() => handleSelectContact(contact)}>
                    <div className="avatar-wrapper">
                      <div className="avatar-luxe">{contact.fullName[0]}</div>
                      <div className="status-indicator online"></div>
                    </div>
                    <div className="chat-info-luxe">
                      <p className="name">{contact.fullName}</p>
                      <p className="meta">{contact.role}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              conversations?.map((conv: any) => (
                <div
                  key={conv.id}
                  className={`chat-item-luxe ${selectedChat?.id === conv.id ? "active" : ""}`}
                  onClick={() => { setSelectedChat(conv); setIsSearchMode(false); }}
                >
                  <div className="avatar-wrapper">
                    <div className="avatar-luxe">{conv.otherUser.fullName[0]}</div>
                    <div className="status-indicator online"></div>
                  </div>
                  <div className="chat-info-luxe">
                    <div className="info-top">
                      <p className="name">{conv.otherUser.fullName}</p>
                      <span className="time">{conv.lastMessage ? new Date(conv.lastMessage.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : ""}</span>
                    </div>
                    <p className="preview">{conv.lastMessage?.content || (isAr ? "ابدأ محادثة..." : "Start chatting...")}</p>
                  </div>
                  {conv.unreadCount > 0 && <div className="unread-badge">{conv.unreadCount}</div>}
                </div>
              ))
            )}
          </div>
        </div>

        {/* Main Chat Area */}
        <div className="chat-main-luxe">
          {selectedChat ? (
            <>
              {/* Chat Header */}
              <div className="chat-header-luxe">
                <div className="header-info-luxe">
                  <div className="avatar-header">{(selectedChat.otherUser?.fullName || selectedChat.fullName)?.[0]}</div>
                  <div className="text-info">
                    <h3>{selectedChat.otherUser?.fullName || selectedChat.fullName}</h3>
                    <div className="status-row">
                      <span className="dot"></span>
                      <span>{isAr ? "متصل الآن" : "Online"}</span>
                    </div>
                  </div>
                </div>
                <div className="header-actions-luxe">
                  <button className="action-btn"><Phone size={18} /></button>
                  <button className="action-btn"><Video size={18} /></button>
                  <button className="action-btn secondary"><MoreVertical size={18} /></button>
                </div>
              </div>

              {/* Messages Window */}
              <div className="messages-window-luxe custom-scrollbar">
                {loadingMessages ? (
                  <div className="loading-state-luxe">
                    <Loader2 className="animate-spin" size={32} />
                  </div>
                ) : (
                  <div className="messages-stack">
                    {messages?.map((msg: any) => {
                      const isMine = msg.senderId === user?.id;
                      const isImage = msg.content?.startsWith('IMAGE:');
                      let imageContent = '';
                      let textContent = msg.content || '';
                      
                      if (isImage) {
                        const contentParts = msg.content.split('\n');
                        imageContent = contentParts[0].replace('IMAGE:', '');
                        textContent = contentParts.slice(1).join('\n');
                      }
                      
                      return (
                        <div key={msg.id} className={`msg-wrapper ${isMine ? "mine" : "theirs"}`}>
                          <div className="msg-bubble-luxe">
                            {isImage && (
                              <div className="message-image">
                                <img 
                                  src={imageContent} 
                                  alt="Attachment" 
                                  onError={(e) => {
                                    e.currentTarget.style.display = 'none';
                                  }}
                                />
                              </div>
                            )}
                            {textContent && (
                              <p className="content">{textContent}</p>
                            )}
                            <div className="msg-meta-luxe">
                              <span>{new Date(msg.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                              {isMine && <CheckCheck size={14} className={msg.readAt ? "read" : ""} />}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                    <div ref={messagesEndRef} />
                  </div>
                )}
              </div>

              {/* Selected Image Preview */}
              {selectedImage && (
                <div className="selected-image-preview">
                  <div className="preview-container">
                    <img src={selectedImage} alt="Selected" />
                    <button className="remove-image-btn" onClick={removeSelectedImage}>
                      <MoreVertical size={16} />
                    </button>
                  </div>
                </div>
              )}

              {/* Input Area */}
              <div className="chat-input-container-luxe">
                <div className="input-bar-luxe">
                  <input 
                    type="file" 
                    ref={fileInputRef} 
                    style={{ display: "none" }} 
                    onChange={handleFileChange} 
                  />
                  <button className="plus-btn" onClick={handleAttachmentClick}>
                    <Plus size={20} />
                  </button>
                  <input
                    type="text"
                    placeholder={isAr ? "اكتب رسالة..." : "Type a message..."}
                    value={messageText}
                    onChange={(e) => setMessageText(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
                  />
                  <button
                    className={`send-btn-luxe ${(messageText.trim() || selectedImage) ? "active" : ""}`}
                    onClick={handleSendMessage}
                    disabled={(!messageText.trim() && !selectedImage) || sendMutation.isPending}
                  >
                    {sendMutation.isPending ? <Loader2 className="animate-spin" size={18} /> : <Send size={18} />}
                  </button>
                </div>
              </div>
            </>
          ) : (
            <div className="empty-chat-luxe">
              <div className="empty-art">
                <div className="art-circle">
                  <MessageCircle size={60} />
                </div>
                <div className="glow-effect"></div>
              </div>
              <h2>{isAr ? `مرحبا بك في بريد ${user?.school?.nameAr || user?.school?.name || "المدرسة"}` : `Welcome to ${user?.school?.name || "School"} Chat`}</h2>
              <p>{isAr ? "اختر محادثة من القائمة الجانبية لبدء التواصل مع المدرسين أو أولياء الأمور." : "Select a conversation or search for a contact to start your professional communication."}</p>
            </div>
          )}
        </div>
      </div>
      <style jsx>{`
        .messages-module-premium {
          height: calc(100vh - -100px);
          display: flex;
          padding: 24px;
          gap: 24px;
          color: var(--glass-text-primary);
        }

        .card-glass-ultra {
          flex: 1;
          display: flex;
          background: var(--glass-bg);
          backdrop-filter: blur(40px);
          border: 1px solid var(--glass-border);
          border-radius: 24px;
          overflow: hidden;
          box-shadow: var(--shadow-xl);
        }

        .chat-sidebar-luxe {
          width: 360px;
          border-inline-end: 1px solid var(--glass-border);
          display: flex;
          flex-direction: column;
          background: var(--glass-input-bg);
        }

        .sidebar-header-luxe {
          padding: 24px;
          border-bottom: 1px solid var(--glass-border);
        }

        .header-top {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 20px;
        }

        .header-top h2 {
          font-size: 22px;
          font-weight: 800;
          color: var(--glass-text-primary);
          letter-spacing: -0.5px;
        }

        .btn-new-chat {
          width: 38px;
          height: 38px;
          border-radius: 10px;
          background: var(--gradient-primary);
          color: #fff;
          border: none;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: 0.3s;
        }

        .search-wrapper-premium {
          display: flex;
          align-items: center;
          gap: 12px;
          background: var(--glass-input-bg);
          border: 1px solid var(--glass-border);
          padding: 10px 14px;
          border-radius: 12px;
        }

        .search-icon { color: var(--glass-text-muted); }

        .search-wrapper-premium input {
          flex: 1;
          background: transparent;
          border: none;
          color: var(--glass-text-primary);
          font-size: 14px;
          outline: none;
        }

        .section-label {
          font-size: 11px;
          font-weight: 800;
          text-transform: uppercase;
          letter-spacing: 1px;
          color: var(--glass-text-muted);
          text-align: center;
          padding: 16px 0 8px;
          border-bottom: 1px solid var(--glass-border);
          margin-bottom: 12px;
        }

        .chat-list-luxe {
          flex: 1;
          overflow-y: auto;
          padding: 8px;
        }

        .chat-item-luxe {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px 16px;
          border-radius: 14px;
          cursor: pointer;
          transition: 0.2s;
          margin-bottom: 4px;
        }

        .chat-item-luxe:hover { background: var(--glass-input-bg); }
        .chat-item-luxe.active { background: var(--primary-glow); }

        .avatar-luxe {
          width: 48px;
          height: 48px;
          border-radius: 12px;
          background: var(--gradient-primary);
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 800;
          font-size: 18px;
          border: 2px solid var(--glass-border);
        }

        .status-indicator {
          position: absolute;
          bottom: -1px;
          inset-inline-end: -1px;
          width: 12px;
          height: 12px;
          border-radius: 50%;
          border: 2px solid var(--glass-bg);
          background: #10b981;
        }

        .chat-info-luxe { flex: 1; min-width: 0; }
        .name { font-weight: 700; color: var(--glass-text-primary); font-size: 15px; }
        .time { font-size: 11px; color: var(--glass-text-muted); }
        .preview { font-size: 13px; color: var(--glass-text-secondary); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

        .chat-main-luxe {
          flex: 1;
          display: flex;
          flex-direction: column;
          background: var(--glass-bg);
          opacity: 0.98;
        }

        .chat-header-luxe {
          padding: 16px 32px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          background: var(--glass-bg);
          border-bottom: 1px solid var(--glass-border);
        }

        .header-info-luxe { display: flex; align-items: center; gap: 14px; }
        .avatar-header {
          width: 44px;
          height: 44px;
          border-radius: 12px;
          background: var(--gradient-primary);
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 800;
          font-size: 18px;
        }

        .text-info h3 { font-size: 16px; font-weight: 800; color: var(--glass-text-primary); margin: 0; }
        .status-row { display: flex; align-items: center; gap: 6px; font-size: 11px; color: #10b981; font-weight: 700; }
        .status-row .dot { width: 6px; height: 6px; background: #10b981; border-radius: 50%; }

        .header-actions-luxe {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .action-btn {
          width: 38px;
          height: 38px;
          border-radius: 10px;
          background: var(--glass-icon-bg);
          border: 1px solid var(--glass-border);
          color: var(--glass-text-secondary);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: 0.2s;
        }
        .action-btn:hover { border-color: var(--primary-light); color: var(--primary-light); }

        .loading-state-luxe {
          height: 100%;
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--primary-light);
        }

        .messages-window-luxe {
          flex: 1;
          overflow-y: auto;
          padding: 24px 32px;
        }

        .messages-stack { display: flex; flex-direction: column; gap: 8px; }
        .msg-bubble-luxe {
          max-width: 65%;
          padding: 12px 18px;
          border-radius: 18px;
          font-size: 15px;
          line-height: 1.5;
        }

        .message-image {
          margin-bottom: 8px;
          border-radius: 12px;
          overflow: hidden;
        }

        .message-image img {
          max-width: 100%;
          max-height: 200px;
          object-fit: cover;
          display: block;
          border-radius: 8px;
        }

        .mine .msg-bubble-luxe {
          background: var(--gradient-primary);
          color: #fff;
          border-bottom-right-radius: ${isAr ? "18px" : "4px"};
          border-bottom-left-radius: ${isAr ? "4px" : "18px"};
        }

        .theirs .msg-bubble-luxe {
          background: var(--glass-input-bg);
          color: var(--glass-text-primary);
          border: 1px solid var(--glass-border);
          border-bottom-left-radius: ${isAr ? "18px" : "4px"};
          border-bottom-right-radius: ${isAr ? "4px" : "18px"};
        }

        .msg-meta-luxe {
          display: flex;
          align-items: center;
          justify-content: flex-end;
          gap: 6px;
          font-size: 10px;
          margin-top: 4px;
          opacity: 0.7;
        }

        .chat-input-container-luxe {
          padding: 20px 32px 32px;
        }

        .selected-image-preview {
          padding: 0 32px 16px;
        }

        .preview-container {
          position: relative;
          display: inline-block;
          max-width: 200px;
        }

        .preview-container img {
          max-width: 100%;
          max-height: 150px;
          object-fit: cover;
          border-radius: 12px;
          border: 2px solid var(--glass-border);
        }

        .remove-image-btn {
          position: absolute;
          top: -8px;
          right: -8px;
          width: 24px;
          height: 24px;
          border-radius: 50%;
          background: var(--glass-icon-bg);
          border: 1px solid var(--glass-border);
          color: var(--glass-text-secondary);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.3s;
        }

        .remove-image-btn:hover {
          background: #ef4444;
          color: white;
          border-color: #ef4444;
        }

        .input-bar-luxe {
          display: flex;
          align-items: center;
          gap: 12px;
          background: var(--glass-input-bg);
          border: 1px solid var(--glass-border);
          padding: 6px 6px 6px 20px;
          border-radius: 16px;
        }

        .input-bar-luxe input {
          flex: 1;
          background: transparent;
          border: none;
          color: var(--glass-text-primary);
          font-size: 15px;
          outline: none;
        }

        .send-btn-luxe {
          width: 42px;
          height: 42px;
          border-radius: 12px;
          background: var(--gradient-primary);
          color: #fff;
          border: none;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        }

        .plus-btn {
          width: 36px;
          height: 36px;
          border-radius: 10px;
          background: var(--glass-icon-bg);
          border: 1px solid var(--glass-border);
          color: var(--glass-text-secondary);
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        .plus-btn:hover {
          background: var(--primary-glow);
          color: var(--primary-light);
          border-color: var(--primary-light);
        }

        .empty-chat-luxe {
          flex: 1;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          text-align: center;
          padding: 40px;
        }

        .art-circle {
          width: 100px;
          height: 100px;
          border-radius: 50%;
          background: var(--primary-glow);
          display: flex;
          align-items: center;
          justify-content: center;
          color: var(--primary-light);
          margin-bottom: 24px;
        }

        .empty-chat-luxe h2 { font-size: 24px; font-weight: 800; color: var(--glass-text-primary); margin-bottom: 12px; }
        .empty-chat-luxe p { color: var(--glass-text-secondary); max-width: 320px; font-size: 15px; }

        .custom-scrollbar::-webkit-scrollbar { width: 5px; }
        .custom-scrollbar::-webkit-scrollbar-thumb { background: var(--glass-border); border-radius: 10px; }5, 0.1); border-radius: 10px; }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover { background: rgba(255, 255, 255, 0.2); }
      `}</style>
    </div>
  );
}
