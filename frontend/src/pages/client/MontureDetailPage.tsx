import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Camera, ShoppingCart, ArrowLeft, Store, Package, CreditCard, Smartphone, Check, MapPin, Navigation, PenLine, Glasses } from 'lucide-react';
import api, { mediaUrl, formatCFA } from '@/lib/api';
import { Monture, Ordonnance, CompagnieAssurance } from '@/types';
import { interpreterOrdonnance, TYPES_VERRES, OPTIONS_VERRES } from '@/utils/ordonnanceUtils';
import VerreSelector from '@/components/VerreSelector';
import toast from 'react-hot-toast';

type MethodePaiement = 'carte_bancaire' | 'orange_money' | 'wave';

const METHODES_PAIEMENT = [
  {
    id: 'orange_money' as MethodePaiement,
    label: 'Orange Money',
    description: 'Paiement mobile Orange',
    icon: <Smartphone className="w-5 h-5" />,
    color: 'border-orange-400 bg-orange-50',
    selectedColor: 'border-orange-500 bg-orange-100 ring-2 ring-orange-400',
    badge: 'bg-orange-500',
  },
  {
    id: 'wave' as MethodePaiement,
    label: 'Wave',
    description: 'Paiement mobile Wave',
    icon: <Smartphone className="w-5 h-5" />,
    color: 'border-blue-300 bg-blue-50',
    selectedColor: 'border-blue-500 bg-blue-100 ring-2 ring-blue-400',
    badge: 'bg-blue-500',
  },
  {
    id: 'carte_bancaire' as MethodePaiement,
    label: 'Carte bancaire',
    description: 'Visa / Mastercard',
    icon: <CreditCard className="w-5 h-5" />,
    color: 'border-gray-300 bg-gray-50',
    selectedColor: 'border-gray-600 bg-gray-100 ring-2 ring-gray-400',
    badge: 'bg-gray-700',
  },
];

export default function MontureDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [selectedImage, setSelectedImage] = useState(0);
  const [ordonnanceId, setOrdonnanceId] = useState('');
  const [assuranceId, setAssuranceId] = useState('');
  const [numeroPolice, setNumeroPolice] = useState('');
  const [notes, setNotes] = useState('');
  const [showOrder, setShowOrder] = useState(false);
  const [simulResult, setSimulResult] = useState<{ montant_rembourse: number; montant_client: number } | null>(null);
  const [methodePaiement, setMethodePaiement] = useState<MethodePaiement>('orange_money');
  const [telephone, setTelephone] = useState('');
  const [adresseLivraison, setAdresseLivraison] = useState('');
  const [modeAdresse, setModeAdresse] = useState<'gps' | 'manuel'>('gps');
  const [gpsCoords, setGpsCoords] = useState<{ lat: number; lng: number } | null>(null);
  const [gpsPrecision, setGpsPrecision] = useState<number | null>(null);
  const [gpsLoading, setGpsLoading] = useState(false);
  const [adresseCorrigee, setAdresseCorrigee] = useState(false);
  const [carteNumero, setCarteNumero] = useState('');
  const [carteExpiry, setCarteExpiry] = useState('');
  const [carteCvv, setCarteCvv] = useState('');
  const [carteTitulaire, setCarteTitulaire] = useState('');
  const [codePromo, setCodePromo] = useState('');
  const [rabaisFamille, setRabaisFamille] = useState(0);
  const [promoInfo, setPromoInfo] = useState<string | null>(null);
  const [avecVerres, setAvecVerres] = useState(false);
  const [typeVerreId, setTypeVerreId] = useState('unifocal_simple');
  const [optionsVerres, setOptionsVerres] = useState<string[]>([]);

  const { data: monture, isLoading } = useQuery<Monture>({
    queryKey: ['monture', id],
    queryFn: () => api.get(`/montures/${id}/`).then(r => r.data),
  });

  const { data: profil } = useQuery({
    queryKey: ['profil'],
    queryFn: () => api.get('/users/profil/').then(r => r.data),
  });

  const { data: ordonnances = [] } = useQuery<Ordonnance[]>({
    queryKey: ['ordonnances'],
    queryFn: () => api.get('/ordonnances/').then(r => r.data.results || r.data),
  });

  const { data: assurances = [] } = useQuery<CompagnieAssurance[]>({
    queryKey: ['compagnies-assurance'],
    queryFn: () => api.get('/assurance/compagnies/').then(r => r.data.results || r.data),
  });

  const simulMutation = useMutation({
    mutationFn: () => api.post('/assurance/simuler/', { compagnie_id: assuranceId, montant: monture?.prix }),
    onSuccess: (res) => setSimulResult(res.data),
    onError: () => toast.error('Erreur lors de la simulation'),
  });

  // Charger le rabais famille dès l'ouverture du formulaire
  const fetchRabaisFamille = async () => {
    try {
      const res = await api.get('/famille/rabais/');
      const taux = res.data.taux ?? 0;
      setRabaisFamille(taux);
      if (taux > 0) {
        setPromoInfo(`Groupe "${res.data.groupe}" — ${Math.round(taux * 100)}% de rabais appliqué`);
      }
    } catch {
      // pas de groupe, pas de rabais
    }
  };

  const obtenirPosition = async () => {
    if (!navigator.geolocation) {
      toast.error("La géolocalisation n'est pas supportée par votre navigateur");
      return;
    }
    setGpsLoading(true);
    setAdresseCorrigee(false);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        const lat = pos.coords.latitude;
        const lng = pos.coords.longitude;
        const precision = Math.round(pos.coords.accuracy); // en mètres
        setGpsCoords({ lat, lng });
        setGpsPrecision(precision);
        try {
          const res = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json`,
            { headers: { 'Accept-Language': 'fr' } }
          );
          const data = await res.json();
          const adresse = data.display_name || `${lat.toFixed(6)}, ${lng.toFixed(6)}`;
          setAdresseLivraison(adresse);
          if (precision > 5000) {
            toast('Position approximative — vérifiez l\'adresse ci-dessous', { icon: '⚠️' });
          } else {
            toast.success('Position obtenue !');
          }
        } catch {
          setAdresseLivraison(`${lat.toFixed(6)}, ${lng.toFixed(6)}`);
          toast.success('Position obtenue !');
        }
        setGpsLoading(false);
      },
      (err) => {
        setGpsLoading(false);
        if (err.code === err.PERMISSION_DENIED)
          toast.error('Accès à la localisation refusé. Vérifiez les permissions du navigateur.');
        else
          toast.error('Impossible d\'obtenir la position');
      },
      { enableHighAccuracy: true, timeout: 15000 }
    );
  };

  const appliquerCodePromo = async () => {
    const code = codePromo.trim().toUpperCase();
    if (!code) return;
    try {
      // Rejoindre le groupe avec le code
      await api.post('/famille/rejoindre/', { code });
      // Récupérer le nouveau taux
      const res = await api.get('/famille/rabais/');
      const taux = res.data.taux ?? 0;
      setRabaisFamille(taux);
      setPromoInfo(`Groupe "${res.data.groupe}" — ${Math.round(taux * 100)}% de rabais appliqué`);
      toast.success('Code promo appliqué !');
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail || 'Code invalide';
      toast.error(msg);
    }
  };

  const orderMutation = useMutation({
    mutationFn: () => {
      const typeVerre = avecVerres ? TYPES_VERRES.find(t => t.id === typeVerreId) : null;
      const optsVerre = avecVerres ? OPTIONS_VERRES.filter(o => optionsVerres.includes(o.id)) : [];
      const prixVerres = typeVerre ? typeVerre.prix + optsVerre.reduce((s, o) => s + o.prix, 0) : 0;
      return api.post('/commandes/passer/', {
        monture: id,
        ordonnance: ordonnanceId || undefined,
        notes,
        methode_paiement: methodePaiement,
        telephone_paiement: methodePaiement !== 'carte_bancaire' ? telephone : undefined,
        adresse_livraison: adresseLivraison,
        latitude: gpsCoords?.lat ?? undefined,
        longitude: gpsCoords?.lng ?? undefined,
        compagnie_assurance_id: assuranceId || undefined,
        numero_police: numeroPolice || undefined,
        rabais_famille: rabaisFamille || undefined,
        type_verre: typeVerre?.id || undefined,
        options_verres: optsVerre.map(o => o.id),
        prix_verres: prixVerres || undefined,
      });
    },
    onSuccess: () => {
      toast.success('Commande passée avec succès !');
      qc.invalidateQueries({ queryKey: ['commandes'] });
      navigate('/commandes');
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.detail
        || (err as { response?: { data?: { detail?: string; message?: string } } })?.response?.data?.message
        || 'Erreur lors de la commande';
      toast.error(msg);
    },
  });

  if (isLoading) return <div className="flex justify-center py-20"><div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary-600" /></div>;
  if (!monture) return <div className="text-center py-20 text-gray-400">Monture introuvable</div>;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const m = monture as any;
  const galerieUrls: string[] = (m.galerie || []).map((g: { image: string }) => mediaUrl(g.image));
  const imageprincipale: string | null = m.image ? mediaUrl(m.image) : m.image_principale ? mediaUrl(m.image_principale) : null;
  const allImages: string[] = galerieUrls.length > 0 ? galerieUrls : imageprincipale ? [imageprincipale] : [];

  const selectedAssurance = assurances.find(a => String(a.id) === assuranceId);
  const montantAssurance = simulResult?.montant_rembourse
    ?? (selectedAssurance ? (Number(monture.prix) * selectedAssurance.taux_prise_charge) / 100 : 0);

  const selectedOrdonnance = ordonnances.find(o => String(o.id) === ordonnanceId) ?? null;
  const profilVisuel = selectedOrdonnance ? interpreterOrdonnance(selectedOrdonnance) : null;

  const typeVerreObj = avecVerres ? TYPES_VERRES.find(t => t.id === typeVerreId) : null;
  const optsVerreObjs = avecVerres ? OPTIONS_VERRES.filter(o => optionsVerres.includes(o.id)) : [];
  const prixVerresTotal = typeVerreObj ? typeVerreObj.prix + optsVerreObjs.reduce((s, o) => s + o.prix, 0) : 0;
  const prixBase = Number(monture.prix) * (1 - rabaisFamille);
  const totalCommande = prixBase + prixVerresTotal - montantAssurance;

  return (
    <div>
      <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-6 text-sm">
        <ArrowLeft className="w-4 h-4" /> Retour au catalogue
      </button>

      <div className="grid lg:grid-cols-2 gap-10">
        <div>
          <div className="bg-gray-100 rounded-2xl overflow-hidden aspect-square mb-4">
            {allImages.length > 0 ? (
              <img src={allImages[selectedImage]} alt={monture.nom} loading="lazy" className="w-full h-full object-cover" />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-gray-300">
                <Package className="w-24 h-24" />
              </div>
            )}
          </div>
          {allImages.length > 1 && (
            <div className="flex gap-2 overflow-x-auto">
              {allImages.map((img, i) => (
                <button key={i} onClick={() => setSelectedImage(i)} className={`w-16 h-16 rounded-xl overflow-hidden border-2 flex-shrink-0 ${i === selectedImage ? 'border-primary-500' : 'border-transparent'}`}>
                  <img src={img} alt="" loading="lazy" className="w-full h-full object-cover" />
                </button>
              ))}
            </div>
          )}
        </div>

        <div>
          <div className="text-sm text-gray-400 font-medium mb-1">{monture.marque}</div>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">{monture.nom}</h1>
          <div className="flex gap-2 mb-4 flex-wrap">
            <span className="badge bg-gray-100 text-gray-600">{monture.forme}</span>
            <span className="badge bg-gray-100 text-gray-600">{monture.couleur}</span>
            <span className="badge bg-gray-100 text-gray-600">{monture.categorie}</span>
          </div>
          <div className="text-3xl font-bold text-primary-600 mb-4">{formatCFA(monture.prix)}</div>
          {monture.description && <p className="text-gray-600 text-sm leading-relaxed mb-4">{monture.description}</p>}
          {monture.boutique && (
            <div className="flex items-center gap-2 text-sm text-gray-500 mb-6 p-3 bg-gray-50 rounded-xl">
              <Store className="w-4 h-4 flex-shrink-0" />
              <div>
                <div className="font-medium text-gray-700">Vendu par {monture.boutique.nom}</div>
                <div className="text-xs">{monture.boutique.adresse}{monture.boutique.telephone ? ` · ${monture.boutique.telephone}` : ''}</div>
              </div>
            </div>
          )}
          <div className="flex gap-3 mb-6">
            <button onClick={() => navigate(`/essai-virtuel/${id}`)} className="btn-secondary flex items-center gap-2 flex-1">
              <Camera className="w-4 h-4" /> Essai virtuel
            </button>
            <button onClick={() => {
              setShowOrder(!showOrder);
              if (!showOrder) {
                if (profil?.adresse) setAdresseLivraison(profil.adresse);
                if (profil?.compagnie_assurance) setAssuranceId(String(profil.compagnie_assurance));
                if (profil?.numero_police) setNumeroPolice(profil.numero_police);
                fetchRabaisFamille();
              }
            }} disabled={monture.stock === 0} className="btn-primary flex items-center gap-2 flex-1 disabled:opacity-50">
              <ShoppingCart className="w-4 h-4" /> {monture.stock === 0 ? 'Rupture de stock' : 'Commander'}
            </button>
          </div>

          {showOrder && (
            <div className="card border border-primary-100 bg-primary-50">
              <h3 className="font-semibold text-gray-900 mb-4">Finaliser la commande</h3>
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Ordonnance (optionnel)</label>
                  <select
                    value={ordonnanceId}
                    onChange={e => {
                      setOrdonnanceId(e.target.value);
                      if (e.target.value) setAvecVerres(true);
                      else { setAvecVerres(false); setTypeVerreId('unifocal_simple'); setOptionsVerres([]); }
                    }}
                    className="input-field"
                  >
                    <option value="">Sans ordonnance</option>
                    {ordonnances.map(o => (
                      <option key={o.id} value={o.id}>
                        Ordonnance du {new Date(o.date_upload).toLocaleDateString('fr-FR')}
                        {o.oeil_droit_sphere != null ? ` (OD: ${o.oeil_droit_sphere > 0 ? '+' : ''}${o.oeil_droit_sphere})` : ''}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Verres correcteurs */}
                <div className={`rounded-xl border-2 transition-all overflow-hidden ${avecVerres ? 'border-primary-200 bg-white' : 'border-gray-200 bg-gray-50'}`}>
                  <button
                    type="button"
                    onClick={() => setAvecVerres(v => !v)}
                    className="w-full flex items-center gap-3 px-4 py-3 text-left"
                  >
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0 ${avecVerres ? 'bg-primary-100 text-primary-600' : 'bg-gray-200 text-gray-400'}`}>
                      <Glasses className="w-5 h-5" />
                    </div>
                    <div className="flex-1">
                      <div className="text-sm font-semibold text-gray-900">Ajouter des verres correcteurs</div>
                      <div className="text-xs text-gray-500">
                        {avecVerres
                          ? (typeVerreObj ? `${typeVerreObj.nom} + options · ${formatCFA(prixVerresTotal)}` : 'Sélectionnez un type de verre')
                          : 'Monture seule — sans verres de correction'}
                      </div>
                    </div>
                    <div className={`w-5 h-5 rounded-full border-2 flex-shrink-0 flex items-center justify-center ${avecVerres ? 'border-primary-500 bg-primary-500' : 'border-gray-300'}`}>
                      {avecVerres && <Check className="w-3 h-3 text-white" />}
                    </div>
                  </button>
                  {avecVerres && (
                    <div className="px-4 pb-4 border-t border-primary-100">
                      <div className="pt-3">
                        <VerreSelector
                          typeVerreId={typeVerreId}
                          setTypeVerreId={setTypeVerreId}
                          optionsChoisies={optionsVerres}
                          setOptionsChoisies={setOptionsVerres}
                          profil={profilVisuel}
                        />
                      </div>
                    </div>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Assurance (optionnel)</label>
                  <div className="flex gap-2">
                    <select value={assuranceId} onChange={e => { setAssuranceId(e.target.value); setSimulResult(null); }} className="input-field">
                      <option value="">Sans assurance</option>
                      {assurances.map(a => (
                        <option key={a.id} value={a.id}>{a.nom} — {a.taux_prise_charge}%</option>
                      ))}
                    </select>
                    {assuranceId && (
                      <button type="button" onClick={() => simulMutation.mutate()} className="btn-secondary text-sm whitespace-nowrap">
                        Simuler
                      </button>
                    )}
                  </div>
                  {assuranceId && (
                    <div className="mt-2">
                      <label className="block text-sm font-medium text-gray-700 mb-1">Numéro de police / adhérent</label>
                      <input
                        value={numeroPolice}
                        onChange={e => setNumeroPolice(e.target.value)}
                        className="input-field"
                        placeholder="Ex: ASS-2024-00123"
                      />
                    </div>
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Adresse de livraison <span className="text-red-500">*</span></label>
                  {/* Sélecteur de mode */}
                  <div className="flex gap-2 mb-3">
                    <button
                      type="button"
                      onClick={() => setModeAdresse('gps')}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium border-2 transition-all ${modeAdresse === 'gps' ? 'border-primary-500 bg-primary-50 text-primary-700' : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'}`}
                    >
                      <MapPin className="w-4 h-4" /> Google Maps
                    </button>
                    <button
                      type="button"
                      onClick={() => { setModeAdresse('manuel'); setGpsCoords(null); }}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium border-2 transition-all ${modeAdresse === 'manuel' ? 'border-primary-500 bg-primary-50 text-primary-700' : 'border-gray-200 bg-white text-gray-500 hover:border-gray-300'}`}
                    >
                      <PenLine className="w-4 h-4" /> Saisir manuellement
                    </button>
                  </div>

                  {modeAdresse === 'gps' ? (
                    <div className="space-y-2">
                      <button
                        type="button"
                        onClick={obtenirPosition}
                        disabled={gpsLoading}
                        className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl border-2 border-dashed border-primary-300 bg-primary-50 text-primary-700 hover:bg-primary-100 transition-all disabled:opacity-60 text-sm font-medium"
                      >
                        <Navigation className={`w-4 h-4 ${gpsLoading ? 'animate-spin' : ''}`} />
                        {gpsLoading ? 'Localisation en cours...' : 'Envoyer ma position GPS'}
                      </button>
                      {gpsCoords && (
                        <div className="space-y-2">
                          {/* Alerte précision faible */}
                          {gpsPrecision !== null && gpsPrecision > 5000 && (
                            <div className="flex items-start gap-2 bg-yellow-50 border border-yellow-200 rounded-xl px-3 py-2 text-xs text-yellow-800">
                              <span className="text-base leading-none mt-0.5">⚠️</span>
                              <div>
                                <strong>Position approximative</strong> (précision : ~{gpsPrecision >= 1000 ? `${Math.round(gpsPrecision / 1000)} km` : `${gpsPrecision} m`}).
                                {' '}Votre appareil n'a pas de GPS — l'adresse détectée peut être incorrecte.
                                Vérifiez et corrigez si nécessaire.
                              </div>
                            </div>
                          )}

                          {/* Miniature carte */}
                          <div className="rounded-xl overflow-hidden border border-gray-200">
                            <div className="bg-gray-50 px-3 py-2 flex items-center justify-between">
                              <span className={`text-xs flex items-center gap-1 ${gpsPrecision !== null && gpsPrecision > 5000 ? 'text-yellow-600' : 'text-gray-500'}`}>
                                <MapPin className={`w-3 h-3 ${gpsPrecision !== null && gpsPrecision > 5000 ? 'text-yellow-500' : 'text-green-500'}`} />
                                {gpsPrecision !== null && gpsPrecision <= 5000 ? `Précision ~${gpsPrecision} m` : 'Position approximative'}
                              </span>
                              <a
                                href={`https://www.google.com/maps?q=${gpsCoords.lat},${gpsCoords.lng}`}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-xs text-primary-600 hover:underline font-medium"
                              >
                                Voir sur Google Maps ↗
                              </a>
                            </div>
                            <iframe
                              title="Localisation"
                              src={`https://maps.google.com/maps?q=${gpsCoords.lat},${gpsCoords.lng}&z=14&output=embed`}
                              className="w-full h-40 border-0"
                              loading="lazy"
                            />
                          </div>

                          {/* Adresse corrigeable */}
                          <div>
                            <div className="flex items-center justify-between mb-1">
                              <span className="text-xs text-gray-500">Adresse détectée</span>
                              {!adresseCorrigee && (
                                <button
                                  type="button"
                                  onClick={() => setAdresseCorrigee(true)}
                                  className="text-xs text-primary-600 hover:underline flex items-center gap-1"
                                >
                                  <PenLine className="w-3 h-3" /> Corriger
                                </button>
                              )}
                            </div>
                            {adresseCorrigee ? (
                              <textarea
                                value={adresseLivraison}
                                onChange={e => setAdresseLivraison(e.target.value)}
                                className="input-field text-sm"
                                rows={2}
                                placeholder="Saisissez votre adresse réelle..."
                                autoFocus
                              />
                            ) : (
                              <p className="text-xs text-gray-700 bg-white border border-gray-200 rounded-xl px-3 py-2 leading-relaxed">
                                📍 {adresseLivraison}
                              </p>
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                  ) : (
                    <textarea
                      value={adresseLivraison}
                      onChange={e => setAdresseLivraison(e.target.value)}
                      className="input-field"
                      rows={2}
                      placeholder="Ex: 12 Rue des Manguiers, Ouagadougou"
                      required
                    />
                  )}
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
                  <input value={notes} onChange={e => setNotes(e.target.value)} className="input-field" placeholder="Instructions particulières..." />
                </div>
                {/* Méthode de paiement */}
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Mode de paiement</label>
                  <div className="grid grid-cols-2 gap-2">
                    {METHODES_PAIEMENT.map(m => (
                      <button
                        key={m.id}
                        type="button"
                        onClick={() => setMethodePaiement(m.id)}
                        className={`relative flex items-center gap-2 p-3 rounded-xl border-2 text-left transition-all ${methodePaiement === m.id ? m.selectedColor : m.color}`}
                      >
                        <span className={`p-1.5 rounded-lg text-white ${m.badge}`}>{m.icon}</span>
                        <div className="min-w-0">
                          <div className="text-sm font-semibold text-gray-900 truncate">{m.label}</div>
                          <div className="text-xs text-gray-500 truncate">{m.description}</div>
                        </div>
                        {methodePaiement === m.id && (
                          <Check className="w-4 h-4 text-gray-700 absolute top-2 right-2 flex-shrink-0" />
                        )}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Champs selon la méthode */}
                {methodePaiement !== 'carte_bancaire' ? (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Numéro de téléphone</label>
                    <input
                      value={telephone}
                      onChange={e => setTelephone(e.target.value)}
                      className="input-field"
                      placeholder="ex: 77 000 00 00"
                      type="tel"
                    />
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Nom du titulaire</label>
                      <input value={carteTitulaire} onChange={e => setCarteTitulaire(e.target.value)} className="input-field" placeholder="Prénom NOM" />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Numéro de carte</label>
                      <input
                        value={carteNumero}
                        onChange={e => setCarteNumero(e.target.value.replace(/\D/g, '').slice(0, 16))}
                        className="input-field font-mono tracking-widest"
                        placeholder="0000 0000 0000 0000"
                        maxLength={16}
                      />
                    </div>
                    <div className="grid grid-cols-2 gap-2">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">Expiration</label>
                        <input
                          value={carteExpiry}
                          onChange={e => {
                            let val = e.target.value.replace(/\D/g, '').slice(0, 4);
                            if (val.length >= 3) val = val.slice(0, 2) + '/' + val.slice(2);
                            setCarteExpiry(val);
                          }}
                          className="input-field font-mono"
                          placeholder="MM/AA"
                          maxLength={5}
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">CVV</label>
                        <input
                          value={carteCvv}
                          onChange={e => setCarteCvv(e.target.value.replace(/\D/g, '').slice(0, 3))}
                          className="input-field font-mono"
                          placeholder="***"
                          type="password"
                          maxLength={3}
                        />
                      </div>
                    </div>
                    <p className="text-xs text-gray-400 flex items-center gap-1">
                      <span>🔒</span> Vos données sont sécurisées. L'intégration bancaire sera disponible prochainement.
                    </p>
                  </div>
                )}

                {/* Code promo / rabais famille */}
                <div className="bg-green-50 border border-green-200 rounded-xl p-3">
                  <label className="block text-sm font-medium text-green-800 mb-2">Code famille / promo</label>
                  {promoInfo ? (
                    <div className="flex items-center gap-2 text-green-700 text-sm">
                      <span className="text-green-500">✓</span>
                      <span>{promoInfo}</span>
                      <button
                        type="button"
                        onClick={() => { setRabaisFamille(0); setPromoInfo(null); setCodePromo(''); }}
                        className="ml-auto text-xs text-gray-400 hover:text-red-500"
                      >
                        Retirer
                      </button>
                    </div>
                  ) : (
                    <div className="flex gap-2">
                      <input
                        value={codePromo}
                        onChange={e => setCodePromo(e.target.value.toUpperCase())}
                        className="input-field text-sm font-mono tracking-widest"
                        placeholder="Ex: RRBA4S"
                        maxLength={6}
                      />
                      <button
                        type="button"
                        onClick={appliquerCodePromo}
                        disabled={!codePromo.trim()}
                        className="btn-primary text-sm whitespace-nowrap disabled:opacity-50"
                      >
                        Appliquer
                      </button>
                    </div>
                  )}
                </div>

                {/* Récapitulatif des prix */}
                <div className="bg-white rounded-xl p-3 text-sm">
                  <div className="flex justify-between text-gray-600 mb-1">
                    <span>Monture</span><span>{formatCFA(monture.prix)}</span>
                  </div>
                  {rabaisFamille > 0 && (
                    <div className="flex justify-between text-green-600 mb-1">
                      <span>Rabais famille ({Math.round(rabaisFamille * 100)}%)</span>
                      <span>− {formatCFA(Number(monture.prix) * rabaisFamille)}</span>
                    </div>
                  )}
                  {avecVerres && typeVerreObj && (
                    <>
                      <div className="flex justify-between text-gray-600 mb-1">
                        <span>{typeVerreObj.nom}</span>
                        <span>{formatCFA(typeVerreObj.prix)}</span>
                      </div>
                      {optsVerreObjs.map(o => (
                        <div key={o.id} className="flex justify-between text-gray-500 mb-1 text-xs">
                          <span>{o.nom}</span><span>+{formatCFA(o.prix)}</span>
                        </div>
                      ))}
                    </>
                  )}
                  {montantAssurance > 0 && (
                    <div className="flex justify-between text-green-600 mb-1">
                      <span>Remboursement assurance</span><span>− {formatCFA(montantAssurance)}</span>
                    </div>
                  )}
                  <div className="flex justify-between font-bold text-gray-900 border-t pt-2 mt-2 text-base">
                    <span>Total à payer</span>
                    <span className="text-primary-600">{formatCFA(totalCommande)}</span>
                  </div>
                </div>
                <button onClick={() => orderMutation.mutate()} disabled={orderMutation.isPending || (modeAdresse === 'gps' ? !gpsCoords : !adresseLivraison.trim())} className="btn-primary w-full disabled:opacity-50">
                  {orderMutation.isPending ? 'Envoi...' : `Payer via ${METHODES_PAIEMENT.find(m => m.id === methodePaiement)?.label}`}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
