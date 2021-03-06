Spree::OrdersController.class_eval do
  after_filter :check_subscriptions, :only => [:populate]

  protected

  # DD: maybe use a format close to OrderPopulator (or move to or decorate there one day)
  # +:subscriptions => { variant_id => interval_id, variant_id => interval_id }
  def check_subscriptions
    return unless params[:subscriptions] && params[:subscriptions][:active].to_s == "1"

    interval_id = params[:subscriptions][:interval_id]

    params[:products].each { |product_id, variant_id| add_subscription(variant_id, interval_id) } if params[:products]
    params[:variants].each { |variant_id, quantity| add_subscription(variant_id, interval_id) } if params[:variants]

    add_subscription(params[:variant_id], params[:subscriptions][:interval_id]) if params[:variant_id]
  end

  # DD: TODO write test for this method
  def add_subscription(variant_id, interval_id)
    line_item = current_order.line_items.where(:variant_id => variant_id).first
    interval = Spree::SubscriptionInterval.find(interval_id)

    # DD: set subscribed price
    if line_item.variant.subscribed_price.present?
      line_item.price = line_item.variant.subscribed_price
    end

    # DD: create subscription
    if line_item.subscription
      line_item.subscription.update_attributes :times => interval.times, :time_unit => interval.time_unit
    else
      line_item.subscription = Spree::Subscription.create :times => interval.times, :time_unit => interval.time_unit
    end

    line_item.save

    line_item.subscription
  end

end