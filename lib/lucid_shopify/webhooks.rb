# frozen_string_literal: true

require 'lucid_shopify/authorized_client'

module LucidShopify
  class Webhooks
    #
    # @param shop_credentials [LucidShopify::ShopCredentials]
    # @param credentials [LucidShopify::Credentials]
    #
    def initialize(shop_credentials, credentials: LucidShopify.credentials)
      @credentials = credentials
      @shop_credentials = shop_credentials
    end

    # @return [LucidShopify::ShopCredentials]
    attr_reader :credentials
    # @return [LucidShopify::ShopCredentials]
    attr_reader :shop_credentials

    #
    # Delete any existing webhooks, then (re)create all webhooks for the shop.
    #
    def create_all
      delete_all

      LucidShopify.webhooks.map do |w|
        Thread.new { create(w) }
      end.map(&:value)
    end

    #
    # Create a webhook.
    #
    # @param webhook [Hash]
    #
    def create(webhook)
      data = {}
      data[:address] = credentials.webhook_uri
      data[:fields] = webhook[:fields] if webhook[:fields]
      data[:topic] = webhook[:topic]

      client.post_json('webhooks', webhook: data)
    end

    #
    # Delete any existing webhooks.
    #
    def delete_all
      webhooks = client.get('webhooks')['webhooks']

      webhooks.map do |w|
        Thread.new { delete(w['id']) }
      end.map(&:value)
    end

    #
    # Delete a webhook.
    #
    # @param id [Integer]
    #
    def delete(id)
      client.delete("webhooks/#{id}")
    end

    private def client
      @client ||= AuthorizedClient.new(shop_credentials)
    end
  end
end

class << LucidShopify
  #
  # Webhooks created for each shop.
  #
  # @return [Array<Hash>]
  #
  # @example
  #   LucidShopify.webhooks << {topic: 'orders/create', fields: %w(id)}
  #
  def webhooks
    @webhooks ||= []
  end
end
