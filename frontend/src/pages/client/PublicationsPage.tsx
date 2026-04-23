import { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Heart, MessageCircle, Plus, Send, Image, X } from 'lucide-react';
import api, { mediaUrl } from '@/lib/api';
import { Publication } from '@/types';
import { useAuth } from '@/contexts/AuthContext';
import toast from 'react-hot-toast';

export default function PublicationsPage() {
  const { user } = useAuth();
  const qc = useQueryClient();
  const fileRef = useRef<HTMLInputElement>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [newPub, setNewPub] = useState({ titre: '', contenu: '', image: null as File | null });
  const [commentTexts, setCommentTexts] = useState<Record<number, string>>({});
  const [expandedComments, setExpandedComments] = useState<Set<number>>(new Set());

  const { data, isLoading } = useQuery({
    queryKey: ['publications'],
    queryFn: () => api.get('/publications/').then(r => r.data),
  });

  const publications: Publication[] = data?.results || data || [];

  const createMutation = useMutation({
    mutationFn: () => {
      const fd = new FormData();
      fd.append('titre', newPub.titre);
      fd.append('contenu', newPub.contenu);
      if (newPub.image) fd.append('image', newPub.image);
      return api.post('/publications/creer/', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
    },
    onSuccess: () => {
      toast.success('Publication créée');
      qc.invalidateQueries({ queryKey: ['publications'] });
      setShowCreate(false);
      setNewPub({ titre: '', contenu: '', image: null });
    },
    onError: () => toast.error('Erreur lors de la création'),
  });

  const likeMutation = useMutation({
    mutationFn: (id: number) => api.post(`/publications/${id}/liker/`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['publications'] }),
  });

  const commentMutation = useMutation({
    mutationFn: ({ id, contenu }: { id: number; contenu: string }) =>
      api.post(`/publications/${id}/commenter/`, { contenu }),
    onSuccess: (_, { id }) => {
      qc.invalidateQueries({ queryKey: ['publications'] });
      setCommentTexts(t => ({ ...t, [id]: '' }));
    },
    onError: () => toast.error('Erreur lors du commentaire'),
  });

  const toggleComments = (id: number) => {
    setExpandedComments(s => {
      const next = new Set(s);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Publications</h1>
        <button onClick={() => setShowCreate(!showCreate)} className="btn-primary flex items-center gap-2">
          {showCreate ? <X className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
          {showCreate ? 'Annuler' : 'Publier'}
        </button>
      </div>

      {showCreate && (
        <div className="card mb-6 border border-primary-100">
          <h2 className="font-semibold text-gray-900 mb-3">Nouvelle publication</h2>
          <div className="space-y-3">
            <input
              value={newPub.titre}
              onChange={e => setNewPub(n => ({ ...n, titre: e.target.value }))}
              className="input-field"
              placeholder="Titre"
              required
            />
            <textarea
              value={newPub.contenu}
              onChange={e => setNewPub(n => ({ ...n, contenu: e.target.value }))}
              className="input-field resize-none"
              rows={4}
              placeholder="Votre message..."
              required
            />
            <div className="flex items-center gap-2">
              <button type="button" onClick={() => fileRef.current?.click()} className="btn-secondary flex items-center gap-2 text-sm">
                <Image className="w-4 h-4" /> {newPub.image ? newPub.image.name : 'Ajouter une image'}
              </button>
              {newPub.image && (
                <button onClick={() => setNewPub(n => ({ ...n, image: null }))} className="text-red-400 hover:text-red-600">
                  <X className="w-4 h-4" />
                </button>
              )}
              <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={e => setNewPub(n => ({ ...n, image: e.target.files?.[0] || null }))} />
            </div>
            <button
              onClick={() => createMutation.mutate()}
              disabled={!newPub.titre || !newPub.contenu || createMutation.isPending}
              className="btn-primary"
            >
              {createMutation.isPending ? 'Publication...' : 'Publier'}
            </button>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="space-y-4">{[...Array(3)].map((_, i) => <div key={i} className="h-40 bg-gray-200 animate-pulse rounded-2xl" />)}</div>
      ) : publications.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <MessageCircle className="w-12 h-12 mx-auto mb-3 opacity-40" />
          <p>Aucune publication</p>
        </div>
      ) : (
        <div className="space-y-4">
          {publications.map(p => (
            <div key={p.id} className="card">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-9 h-9 bg-primary-100 rounded-full flex items-center justify-center text-primary-700 font-bold text-sm">
                  {(p.auteur_nom?.[0] || '?').toUpperCase()}
                </div>
                <div>
                  <div className="font-medium text-sm text-gray-900">{p.auteur_nom || 'Auteur'}</div>
                  <div className="text-xs text-gray-400">{new Date(p.date_creation).toLocaleDateString('fr-FR')}</div>
                </div>
              </div>
              <h3 className="font-semibold text-gray-900 mb-1">{p.titre}</h3>
              <p className="text-gray-600 text-sm leading-relaxed mb-3">{p.contenu}</p>
              {p.image && (
                <img src={mediaUrl(p.image)} alt={p.titre} loading="lazy" className="w-full rounded-xl object-cover max-h-64 mb-3" />
              )}
              <div className="flex items-center gap-4 border-t pt-3">
                <button
                  onClick={() => likeMutation.mutate(p.id)}
                  className={`flex items-center gap-1.5 text-sm transition-colors ${p.liked ? 'text-red-500' : 'text-gray-500 hover:text-red-500'}`}
                >
                  <Heart className={`w-4 h-4 ${p.liked ? 'fill-current' : ''}`} />
                  {p.likes}
                </button>
                <button
                  onClick={() => toggleComments(p.id)}
                  className="flex items-center gap-1.5 text-sm text-gray-500 hover:text-primary-600 transition-colors"
                >
                  <MessageCircle className="w-4 h-4" />
                  {p.commentaires_count || 0}
                </button>
              </div>

              {expandedComments.has(p.id) && (
                <div className="mt-3 border-t pt-3 space-y-2">
                  {p.commentaires?.map(c => (
                    <div key={c.id} className="flex gap-2">
                      <div className="w-7 h-7 bg-gray-100 rounded-full flex items-center justify-center text-gray-600 font-bold text-xs flex-shrink-0">
                        {(c.auteur_nom?.[0] || '?').toUpperCase()}
                      </div>
                      <div className="bg-gray-50 rounded-xl px-3 py-2 flex-1">
                        <div className="text-xs font-medium text-gray-700">{c.auteur_nom || 'Utilisateur'}</div>
                        <div className="text-sm text-gray-600">{c.contenu}</div>
                      </div>
                    </div>
                  ))}
                  <div className="flex gap-2 mt-2">
                    <input
                      value={commentTexts[p.id] || ''}
                      onChange={e => setCommentTexts(t => ({ ...t, [p.id]: e.target.value }))}
                      className="input-field text-sm"
                      placeholder="Écrire un commentaire..."
                      onKeyDown={e => {
                        if (e.key === 'Enter' && commentTexts[p.id]?.trim()) {
                          commentMutation.mutate({ id: p.id, contenu: commentTexts[p.id] });
                        }
                      }}
                    />
                    <button
                      onClick={() => { if (commentTexts[p.id]?.trim()) commentMutation.mutate({ id: p.id, contenu: commentTexts[p.id] }); }}
                      className="p-2 bg-primary-600 text-white rounded-xl hover:bg-primary-700"
                    >
                      <Send className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
