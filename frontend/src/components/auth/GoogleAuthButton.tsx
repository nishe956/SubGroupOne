import { GoogleLogin, CredentialResponse } from '@react-oauth/google';
import toast from 'react-hot-toast';

export default function GoogleAuthButton({ onSuccess }: { onSuccess: (credential: string) => void }) {
  return (
    <div className="mt-5">
      <div className="flex items-center gap-3 mb-4">
        <div className="flex-1 h-px bg-gray-200" />
        <span className="text-xs text-gray-400 font-medium">ou</span>
        <div className="flex-1 h-px bg-gray-200" />
      </div>
      <div className="flex justify-center">
        <GoogleLogin
          onSuccess={(res: CredentialResponse) => res.credential && onSuccess(res.credential)}
          onError={() => toast.error('La connexion avec Google a échoué.')}
          text="continue_with"
          shape="pill"
          width="320"
        />
      </div>
    </div>
  );
}
