# frozen_string_literals: true

Rails.application.routes.draw do
  resource :payment_method

  namespace :braintree do
    resource :payment_method, namespace: :braintree
    resources :subscriptions do
      member do
        patch :cancel
        patch :resume
      end
    end
    resources :charges do
      member do
        patch :refund
      end
    end
  end

  namespace :paddle_billing do
    resource :payment_method, namespace: :paddle_billing
    resources :subscriptions do
      member do
        patch :cancel
        patch :resume
      end
    end
    resources :charges do
      member do
        patch :refund
      end
    end
  end

  namespace :paddle_classic do
    resource :payment_method, namespace: :paddle
    resources :subscriptions do
      member do
        patch :cancel
        patch :resume
      end
    end
    resources :charges do
      member do
        patch :refund
      end
    end
  end

  namespace :stripe do
    resource :payment_method, namespace: :stripe
    resources :subscriptions do
      member do
        patch :cancel
        patch :resume
      end
    end
    resources :charges do
      member do
        patch :refund
      end
    end
    namespace :charges do
      resource :import
    end
    resource :checkout, namespace: :stripe
  end

  namespace :mercadopago do
    resource :payment_method, namespace: :mercadopago
    resources :subscriptions do
      member do
        patch :cancel
        patch :resume
      end
    end
    resources :charges do
      member do
        patch :refund
      end
    end
    namespace :charges do
      resource :import
    end
    resource :checkout, namespace: :mercadopago
  end

  root to: "main#show"
end
