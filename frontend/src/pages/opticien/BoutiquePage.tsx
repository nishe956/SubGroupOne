import { useState, useRef, useEffect, FormEvent } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Store, Phone, MapPin, Upload } from 'lucide-react';
import api, { mediaUrl } from '@/lib/api';
import toast from 'react-hot-toast';

interface BoutiqueData {
  id?: number;
  nom?: string;
  adresse?: string;
  telephone?: string;
  description?: string;
  logo?: string;
}

export default function BoutiquePage() {
  const qc = useQueryClient();
  const logoRef = useRef<HTMLInputElement>(null);

  const { data: boutique, isLoading } = useQuery<BoutiqueData>({
    queryKey: ['ma-boutique'],
    queryFn: () => api.get('/boutiques/ma-boutique/').then(r => r.data),
  });

  const [form, setForm] = useState({
    nom: '', adresse: '', telephone: '', description: '',
  });

  useEffect(() => {
    if (boutique) {
      setForm({
        nom: boutique.nom || '',
        adresse: boutique.adresse || '',
        telephone: boutique.telephone || '',
        description: boutique.description || '',
      });
    }
  }, [boutique]);

  const updateMutation = useMutation({
    mutationFn: (logo?: File) => {
      const fd = new FormData();
      Object.entries(form).forEach(([k, v]) => fd.append(k, v));
      if (logo) fd.append('logo', logo);
      return api.put('/boutiques/ma-boutique/', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
    },
    onSuccess: (res) => {
      toast.success('Boutique mise à jour');
      qc.invalidateQueries({ queryKey: ['ma-boutique'] });
      setForm({
        nom: res.data.nom || '',
        adresse: res.data.adresse || '',
        telephone: res.data.telephone || '',
        description: res.data.description || '',
      });
    },
    onError: () => toast.error('Erreur lors de la mise à jour'),
  });

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const logo = logoRef.current?.files?.[0];
    updateMutation.mutate(logo);
  };

  if (isLoading) return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" /></div>;

  const logoSrc = boutique?.logo ? mediaUrl(boutique.logo) : null;

  return (
    <div className="max-w-2xl">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Ma boutique</h1>

      <div className="card">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-20 h-20 bg-gray-100 rounded-2xl overflow-hidden flex-shrink-0 flex items-center justify-center">
            {logoSrc ? (
              <img src={logoSrc} alt="Logo boutique" loading="lazy" className="w-full h-full object-cover" />
            ) : (
              <Store className="w-10 h-10 text-gray-300" />
            )}
          </div>
          <div>
            <h2 className="font-bold text-xl text-gray-900">{boutique?.nom || 'Ma boutique'}</h2>
            {boutique?.adresse && (
              <div className="flex items-center gap-1 text-sm text-gray-500 mt-1">
                <MapPin className="w-3.5 h-3.5" /> {boutique.adresse}
              </div>
            )}
            {boutique?.telephone && (
              <div className="flex items-center gap-1 text-sm text-gray-500">
                <Phone className="w-3.5 h-3.5" /> {boutique.telephone}
              </div>
            )}
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Nom de la boutique</label>
            <input
              value={form.nom}
              onChange={e => setForm(f => ({ ...f, nom: e.target.value }))}
              className="input-field"
              placeholder="Optique Vision Plus"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Adresse</label>
            <input
              value={form.adresse}
              onChange={e => setForm(f => ({ ...f, adresse: e.target.value }))}
              className="input-field"
              placeholder="Secteur 10, Avenue Kwamé N'Krumah, Ouagadougou"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Téléphone</label>
            <input
              value={form.telephone}
              onChange={e => setForm(f => ({ ...f, telephone: e.target.value }))}
              className="input-field"
              placeholder="+226 25 00 00 00"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Description</label>
            <textarea
              value={form.description}
              onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
              className="input-field resize-none"
              rows={3}
              placeholder="Décrivez votre boutique..."
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Logo</label>
            <button type="button" onClick={() => logoRef.current?.click()} className="btn-secondary flex items-center gap-2 text-sm">
              <Upload className="w-4 h-4" /> Changer le logo
            </button>
            <input ref={logoRef} type="file" accept="image/*" className="hidden" />
          </div>
          <button type="submit" disabled={updateMutation.isPending} className="btn-primary">
            {updateMutation.isPending ? 'Sauvegarde...' : 'Enregistrer'}
          </button>
        </form>
      </div>
    </div>
  );
}
